import SwiftUI

struct AuthViewNew: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State var isSignUp: Bool = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Header
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(mintGreen.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundColor(mintGreen)
                            }
                            
                            Text("Business Blueprint")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.black)
                            
                            Text(isSignUp ? "Start your entrepreneurial journey" : "Welcome back to your journey")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Form
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.black)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.black)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            if let error = viewModel.errorMessage {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            Button {
                                if isSignUp {
                                    viewModel.signUp(email: email, password: password)
                                } else {
                                    viewModel.signIn(email: email, password: password)
                                }
                            } label: {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: isSignUp ? "person.badge.plus.fill" : "arrow.right.circle.fill")
                                    }
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(mintGreen)
                                .cornerRadius(12)
                            }
                            .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                            
                            Button {
                                isSignUp.toggle()
                            } label: {
                                HStack {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .foregroundColor(.gray)
                                    Text(isSignUp ? "Sign In" : "Sign Up")
                                        .foregroundColor(mintGreen)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: viewModel.isLoggedIn) { _, newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    private var mintGreen: Color {
        Color(red: 0.0, green: 0.8, blue: 0.6)
    }
}

#Preview {
    AuthViewNew(viewModel: AuthViewModel())
}