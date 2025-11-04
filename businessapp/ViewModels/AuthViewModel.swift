import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userId: String?
    @Published var email: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let userIdKey = "userId"
    private let emailKey = "userEmail"
    
    func signUp(email: String, password: String) {
        isLoading = true
        FirebaseService.shared.signUpUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let uid):
                    self.userId = uid
                    self.email = email
                    self.isLoggedIn = true
                    UserDefaults.standard.set(uid, forKey: self.userIdKey)
                    UserDefaults.standard.set(email, forKey: self.emailKey)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signIn(email: String, password: String) {
        isLoading = true
        FirebaseService.shared.signInUser(email: email, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isLoading = false
                switch result {
                case .success(let uid):
                    self.userId = uid
                    self.email = email
                    self.isLoggedIn = true
                    UserDefaults.standard.set(uid, forKey: self.userIdKey)
                    UserDefaults.standard.set(email, forKey: self.emailKey)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func signOut() {
        FirebaseService.shared.signOutUser { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case .success:
                    self.isLoggedIn = false
                    self.userId = nil
                    self.email = nil
                    UserDefaults.standard.removeObject(forKey: self.userIdKey)
                    UserDefaults.standard.removeObject(forKey: self.emailKey)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func checkLoginStatus() {
        if let savedUserId = UserDefaults.standard.string(forKey: userIdKey) {
            userId = savedUserId
            email = UserDefaults.standard.string(forKey: emailKey)
            isLoggedIn = true
        }
    }
}
