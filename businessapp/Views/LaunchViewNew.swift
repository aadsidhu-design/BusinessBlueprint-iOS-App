import SwiftUI

struct LaunchViewNew: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // App Icon/Logo
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 20, y: 10)
                    
                    VStack(spacing: 8) {
                        Text("Business Blueprint")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Build your dream business")
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                .opacity(opacity)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        showSignUp = true
                    } label: {
                        Text("Get Started")
                    }
                    .buttonStyle(ModernButtonStyle())
                    
                    Button {
                        showSignIn = true
                    } label: {
                        Text("Sign In")
                    }
                    .buttonStyle(GhostButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(opacity)
            }
        }
        .sheet(isPresented: $showSignUp) {
            AuthViewNew(isSignUp: true)
                .environmentObject(authVM)
        }
        .sheet(isPresented: $showSignIn) {
            AuthViewNew(isSignUp: false)
                .environmentObject(authVM)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1
            }
        }
    }
}
