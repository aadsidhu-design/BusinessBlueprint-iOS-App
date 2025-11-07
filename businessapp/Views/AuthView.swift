import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State var isSignUp: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppColors.primaryOrange.opacity(0.2), AppColors.primaryPink.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: isSignUp ? "person.badge.plus.fill" : "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(AppColors.primaryGradient)
                            }
                            .bounceEntrance()
                            
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .fadeInUp(delay: 0.1)
                            
                            Text(isSignUp ? "Start your entrepreneurial journey" : "Continue where you left off")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .fadeInUp(delay: 0.2)
                        }
                        
                        // Form
                        VStack(spacing: 20) {
                            ModernTextField(
                                title: "Email",
                                text: $email,
                                placeholder: "you@example.com",
                                icon: "envelope.fill"
                            )
                            .fadeInUp(delay: 0.3)
                            
                            ModernTextField(
                                title: "Password",
                                text: $password,
                                placeholder: "Enter your password",
                                isSecure: true,
                                icon: "lock.fill"
                            )
                            .fadeInUp(delay: 0.4)
                            
                            if let error = viewModel.errorMessage {
                                ModernCard(
                                    borderColor: .red.opacity(0.5),
                                    padding: 12
                                ) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .fadeInUp()
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Action Button
                        VStack(spacing: 16) {
                            PlayfulButton(
                                title: isSignUp ? "Create Account" : "Sign In",
                                icon: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill",
                                gradient: AppColors.primaryGradient,
                                isLoading: viewModel.isLoading,
                                disabled: email.isEmpty || password.isEmpty
                            ) {
                                if isSignUp {
                                    viewModel.signUp(email: email, password: password)
                                } else {
                                    viewModel.signIn(email: email, password: password)
                                }
                            }
                            .fadeInUp(delay: 0.5)
                            
                            Button {
                                isSignUp.toggle()
                            } label: {
                                HStack {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .foregroundColor(.secondary)
                                    Text(isSignUp ? "Sign In" : "Sign Up")
                                        .foregroundColor(AppColors.primaryOrange)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                            .fadeInUp(delay: 0.6)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title3)
                    }
                }
            }
            .onChange(of: viewModel.isLoggedIn) { _, newValue in
                if newValue {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel())
}
