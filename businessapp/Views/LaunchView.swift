import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 30
    
    var body: some View {
        ZStack {
            // Gradient Background
            AppColors.vibrantGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 40) {
                    Spacer()
                        .frame(height: 60)
                    
                    // Animated Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 20)
                        
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.primaryOrange, AppColors.primaryPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            .shadow(color: AppColors.primaryOrange.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .bounceEntrance()
                    
                    // Title Section
                    VStack(spacing: 16) {
                        Text("Business Blueprint")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .fadeInUp(delay: 0.2)
                        
                        Text("Discover your perfect business idea\npowered by AI")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .fadeInUp(delay: 0.3)
                        
                        // Feature Pills
                        HStack(spacing: 12) {
                            FeaturePill(icon: "sparkles", text: "AI-Powered")
                            FeaturePill(icon: "rocket.fill", text: "Fast")
                            FeaturePill(icon: "star.fill", text: "Personalized")
                        }
                        .fadeInUp(delay: 0.4)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        PlayfulButton(
                            title: "Get Started",
                            icon: "arrow.right.circle.fill",
                            gradient: AppColors.primaryGradient
                        ) {
                            showSignUp = true
                        }
                        .fadeInUp(delay: 0.5)
                        
                        Button {
                            showSignIn = true
                        } label: {
                            Text("Sign In")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                        .fadeInUp(delay: 0.6)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            AuthView(viewModel: authVM, isSignUp: true)
        }
        .sheet(isPresented: $showSignIn) {
            AuthView(viewModel: authVM, isSignUp: false)
        }
        .onAppear {
            withAnimation(AnimationHelpers.scaleBounce()) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

private struct FeaturePill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.25))
        )
    }
}

#Preview {
    LaunchView()
        .environmentObject(AuthViewModel())
}
