import Foundation
import SwiftUI
import Combine
import CryptoKit
import AuthenticationServices
import FirebaseAuth
import FirebaseAnalytics
import FirebaseCore
import GoogleSignIn

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var isLoggedIn = false
    @Published var userId: String?
    @Published var email: String?
    @Published var displayName: String?
    @Published var photoURL: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var userIsAnonymous = false
    
    private var authListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    private let firebase = FirebaseService.shared
    
    override init() {
        super.init()
        authListener = firebase.listenToAuthChanges { [weak self] user in
            Task { await self?.handleAuthChange(user: user) }
        }
    }
    
    deinit {
        Task { @MainActor in
            firebase.removeAuthListener(authListener)
        }
    }
    
    private func handleAuthChange(user: User?) async {
        if let user {
            userId = user.uid
            email = user.email
            displayName = user.displayName
            photoURL = user.photoURL?.absoluteString
            userIsAnonymous = user.isAnonymous
            isLoggedIn = true
            if let email = email {
                Analytics.logEvent(AnalyticsEventLogin, parameters: ["provider": user.providerData.first?.providerID ?? "password", "email": email])
            }
        } else {
            userId = nil
            email = nil
            displayName = nil
            photoURL = nil
            userIsAnonymous = false
            isLoggedIn = false
        }
    }
    
    // MARK: - Email / Password
    func signUp(email: String, password: String) {
        isLoading = true
        firebase.signUpUser(email: email, password: password) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        firebase.signInUser(email: email, password: password) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success:
                self.errorMessage = nil
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Anonymous
    func signInAnonymously() {
        isLoading = true
        firebase.signInAnonymously { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            if case let .failure(error) = result {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = nil
            }
        }
    }
    
    // MARK: - Google
    func signInWithGoogle(presenting viewController: UIViewController) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Missing Google client ID"
            return
        }
        isLoading = true
        let configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = configuration
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            guard let self else { return }
            Task { @MainActor in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                guard let result else {
                    self.errorMessage = "Google sign-in failed"
                    self.isLoading = false
                    return
                }
                self.processGoogleSignInResult(result)
            }
        }
    }
    
    private func processGoogleSignInResult(_ result: GIDSignInResult) {
        guard let idToken = result.user.idToken?.tokenString else {
            self.errorMessage = "Missing Google ID token"
            self.isLoading = false
            return
        }
        let accessToken = result.user.accessToken.tokenString
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        self.firebase.signInWithCredential(credential, provider: "google") { authResult in
            Task { @MainActor in
                self.isLoading = false
                if case let .failure(error) = authResult {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Apple
    func prepareAppleSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid Apple credential"
                return
            }
            guard let nonce = currentNonce else {
                errorMessage = "Invalid state: missing login request"
                return
            }
            guard let appleIDToken = credential.identityToken,
                  let tokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to process Apple ID token"
                return
            }
            let firebaseCredential = OAuthProvider.appleCredential(withIDToken: tokenString, rawNonce: nonce, fullName: credential.fullName)
            isLoading = true
            firebase.signInWithCredential(firebaseCredential, provider: "apple") { [weak self] authResult in
                guard let self else { return }
                self.isLoading = false
                if case let .failure(error) = authResult {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.errorMessage = nil
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try firebase.signOutUser()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Helpers
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess { fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)") }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
