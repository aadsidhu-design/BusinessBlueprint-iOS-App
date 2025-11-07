import SwiftUI

struct AuthViewNew: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    var isSignUp: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Header
                        VStack(spacing: 12) {
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)
                            
                            Text(isSignUp ? "Start building your business" : "Sign in to continue")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        // Form
                        VStack(spacing: 16) {
                            CleanTextField(
                                title: "Email",
                                text: $email,
                                icon: "envelope"
                            )
                            
                            CleanTextField(
                                title: "Password",
                                text: $password,
                                icon: "lock",
                                isSecure: true
                            )
                            
                            if let error = authVM.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Action Button
                        Button {
                            if isSignUp {
                                authVM.signUp(email: email, password: password)
                            } else {
                                authVM.signIn(email: email, password: password)
                            }
                        } label: {
                            if authVM.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                            }
                        }
                        .buttonStyle(ModernButtonStyle())
                        .disabled(email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .onChange(of: authVM.isLoggedIn) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}
