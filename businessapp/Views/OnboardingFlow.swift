import SwiftUI

struct OnboardingFlow: View {
    @State private var currentStep = 0
    @State private var showQuiz = false
    @Environment(\.dismiss) private var dismiss
    
    private let onboardingSteps: [OnboardingStep] = [
        OnboardingStep(
            icon: "sparkles",
            title: "Welcome to Business Blueprint",
            description: "Your AI-powered entrepreneurship companion that turns ideas into actionable business plans.",
            primaryAction: "Get Started",
            features: [
                "AI-generated business ideas tailored to you",
                "Interactive planning and progress tracking",
                "Smart suggestions and coaching"
            ]
        ),
        OnboardingStep(
            icon: "brain.head.profile",
            title: "Personalized Strategy",
            description: "We'll analyze your skills, personality, and interests to generate the perfect business opportunities.",
            primaryAction: "Take Quiz",
            features: [
                "Skills-based opportunity matching",
                "Personality-driven business models",
                "Interest-aligned market analysis"
            ]
        ),
        OnboardingStep(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            description: "Monitor milestones, manage goals, and get AI coaching to accelerate your entrepreneurial journey.",
            primaryAction: "Start Journey",
            features: [
                "Real-time progress tracking",
                "Goal management and reminders",
                "AI mentor for guidance"
            ]
        )
    ]
    
    var body: some View {
        ZStack {
            AppColors.vibrantGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingSteps.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index <= currentStep ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 4)
                            .animation(AnimationHelpers.smoothSpring, value: currentStep)
                    }
                }
                .padding()
                
                // Content
                TabView(selection: $currentStep) {
                    ForEach(0..<onboardingSteps.count, id: \.self) { index in
                        OnboardingStepView(step: onboardingSteps[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation
                VStack(spacing: 16) {
                    PlayfulButton(
                        title: onboardingSteps[currentStep].primaryAction,
                        icon: currentStep == onboardingSteps.count - 1 ? "checkmark.circle.fill" : "arrow.right.circle.fill",
                        gradient: AppColors.primaryGradient
                    ) {
                        handlePrimaryAction()
                    }
                    .padding(.horizontal, 24)
                    
                    HStack {
                        if currentStep > 0 {
                            Button {
                                withAnimation(AnimationHelpers.buttonPress) {
                                    currentStep -= 1
                                }
                            } label: {
                                Text("Back")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        if currentStep < onboardingSteps.count - 1 {
                            Button {
                                withAnimation(AnimationHelpers.buttonPress) {
                                    currentStep += 1
                                }
                            } label: {
                                Text("Next")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Skip")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showQuiz) {
            QuizView()
        }
    }
    
    private func handlePrimaryAction() {
        switch currentStep {
        case 0:
            withAnimation(AnimationHelpers.buttonPress) {
                currentStep = 1
            }
        case 1:
            showQuiz = true
        case 2:
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            dismiss()
        default:
            break
        }
    }
}

struct OnboardingStep {
    let icon: String
    let title: String
    let description: String
    let primaryAction: String
    let features: [String]
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 60)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: step.icon)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                }
                .bounceEntrance()
                
                // Content
                VStack(spacing: 20) {
                    Text(step.title)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fadeInUp(delay: 0.2)
                    
                    Text(step.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .fadeInUp(delay: 0.3)
                }
                
                // Features
                ModernCard(
                    gradient: LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    borderColor: Color.white.opacity(0.3),
                    padding: 24
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(step.features.enumerated()), id: \.offset) { index, feature in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title3)
                                Text(feature)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            .fadeInUp(delay: Double(index) * 0.1 + 0.4)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                    .frame(height: 40)
            }
        }
    }
}

#Preview {
    OnboardingFlow()
}
