import SwiftUI

struct QuizView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = QuizViewModel()
    @State private var firstName = ""
    @State private var lastName = ""
    var onComplete: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                ProgressView(value: Double(stepProgress()), total: 5.0)
                    .tint(Color(red: 1, green: 0.6, blue: 0.2))
                    .padding(20)
                
                ScrollView {
                    VStack(spacing: 24) {
                        switch viewModel.currentStep {
                        case .welcome:
                            WelcomeStepView()
                        case .skills:
                            SkillsStepView(viewModel: viewModel)
                        case .personality:
                            PersonalityStepView(viewModel: viewModel)
                        case .interests:
                            InterestsStepView(viewModel: viewModel)
                        case .personalInfo:
                            PersonalInfoStepView(firstName: $firstName, lastName: $lastName)
                        case .loading:
                            LoadingStepView()
                        case .results:
                            ResultsStepView(viewModel: viewModel)
                        }
                    }
                    .padding(20)
                }
                
                HStack(spacing: 12) {
                    if viewModel.currentStep != .welcome && viewModel.currentStep != .results {
                        Button(action: { viewModel.previousStep() }) {
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .foregroundColor(.white)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    
                    if viewModel.currentStep == .results {
                        Button(action: completeQuiz) {
                            Text("Continue to Dashboard")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1, green: 0.6, blue: 0.2),
                                            Color(red: 1, green: 0.4, blue: 0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .opacity(viewModel.isLoading ? 0.6 : 1)
                    } else if viewModel.currentStep != .loading {
                        Button(action: { viewModel.nextStep() }) {
                            Text("Next")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 1, green: 0.6, blue: 0.2),
                                            Color(red: 1, green: 0.4, blue: 0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!canAdvance)
                        .opacity(canAdvance ? 1 : 0.5)
                    }
                }
                .padding(20)
            }
        }
    }
    
    private var canAdvance: Bool {
        switch viewModel.currentStep {
        case .skills:
            return !viewModel.selectedSkills.isEmpty
        case .personality:
            return !viewModel.selectedPersonality.isEmpty
        case .interests:
            return !viewModel.selectedInterests.isEmpty
        case .personalInfo:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .welcome, .loading, .results:
            return true
        }
    }
    
    private func completeQuiz() {
        guard !viewModel.isLoading else { return }
        let sanitizedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let userId = authVM.userId ?? UUID().uuidString
        let email = authVM.email ?? "founder@businessblueprint.app"
        let profile = UserProfile(
            id: userId,
            email: email,
            firstName: sanitizedFirstName.isEmpty ? "Founder" : sanitizedFirstName,
            lastName: sanitizedLastName,
            skills: Array(viewModel.selectedSkills).sorted(),
            personality: Array(viewModel.selectedPersonality).sorted(),
            interests: Array(viewModel.selectedInterests).sorted(),
            createdAt: Date(),
            subscriptionTier: "free"
        )
        
        var generatedIdeas = viewModel.businessIdeas
        if generatedIdeas.isEmpty {
            generatedIdeas = QuizViewModel.fallbackIdeas(
                for: userId,
                skills: profile.skills,
                personality: profile.personality,
                interests: profile.interests
            )
        }
        let personalizedIdeas = generatedIdeas.map { $0.withUserId(userId) }
        businessPlanStore.applyQuizResults(profile: profile, ideas: personalizedIdeas)
        onComplete?()
    }
    
    func stepProgress() -> Int {
        switch viewModel.currentStep {
        case .welcome: return 1
        case .skills: return 2
        case .personality: return 3
        case .interests: return 4
        case .personalInfo: return 5
        default: return 5
        }
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("Let's Discover Your Perfect Business!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            Text("Answer a few quick questions and our AI will generate personalized business ideas tailored to your unique skills, personality, and interests.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(2)
            
            VStack(spacing: 12) {
                InfoBadge("⏱️ Takes about 5 minutes")
                InfoBadge("🤖 Powered by advanced AI")
                InfoBadge("🎯 Completely personalized")
            }
        }
    }
}

struct SkillsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("What are your key skills?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select all that apply")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.isGeneratingOptions {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(0.8)
                        Text("AI")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.allSkills, id: \.self) { skill in
                    ToggleChip(
                        label: skill,
                        isSelected: viewModel.selectedSkills.contains(skill),
                        action: { viewModel.toggleSkill(skill) }
                    )
                }
            }
        }
    }
}

struct PersonalityStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Describe your personality")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Choose traits that define you")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.isGeneratingOptions {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(0.8)
                        Text("AI")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.allPersonality, id: \.self) { trait in
                    ToggleChip(
                        label: trait,
                        isSelected: viewModel.selectedPersonality.contains(trait),
                        action: { viewModel.togglePersonality(trait) }
                    )
                }
            }
        }
    }
}

struct InterestsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading) {
                    Text("What interests you?")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select your areas of interest")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.isGeneratingOptions {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                            .scaleEffect(0.8)
                        Text("AI")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                }
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.allInterests, id: \.self) { interest in
                    ToggleChip(
                        label: interest,
                        isSelected: viewModel.selectedInterests.contains(interest),
                        action: { viewModel.toggleInterest(interest) }
                    )
                }
            }
        }
    }
}

struct PersonalInfoStepView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tell us about yourself")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                TextField("First Name", text: $firstName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                
                TextField("Last Name", text: $lastName)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
        }
    }
}

struct LoadingStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            // AI Brain Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                ProgressView()
                    .scaleEffect(2.5)
                    .tint(.white.opacity(0.8))
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                    Text("AI is Thinking...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text("Google Gemini is analyzing your profile and generating personalized business ideas tailored just for you")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // AI Process Steps
            VStack(alignment: .leading, spacing: 16) {
                AIProcessStep(icon: "person.crop.circle.fill.badge.checkmark", text: "Analyzing your skills & personality")
                AIProcessStep(icon: "lightbulb.fill", text: "Generating innovative ideas")
                AIProcessStep(icon: "chart.line.uptrend.xyaxis", text: "Calculating viability scores")
                AIProcessStep(icon: "star.fill", text: "Personalizing recommendations")
            }
            .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }
}

struct AIProcessStep: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.orange)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

struct ResultsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Profile Complete!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Your personalized business dashboard is ready")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            
            VStack(alignment: .leading, spacing: 16) {
                FeatureItem(icon: "lightbulb.fill", title: "AI Business Ideas", description: "Get personalized recommendations")
                FeatureItem(icon: "chart.line.uptrend.xyaxis", title: "Progress Tracking", description: "Track goals and milestones")
                FeatureItem(icon: "sparkles", title: "AI Assistant", description: "Get guidance whenever you need")
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            
            if !viewModel.businessIdeas.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Recommendations")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.businessIdeas.prefix(3)) { idea in
                            IdeaCardCompact(idea: idea)
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
}

struct ToggleChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                Spacer()
            }
            .padding(14)
            .background(isSelected ? Color(red: 1, green: 0.6, blue: 0.2).opacity(0.8) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .foregroundColor(.white)
        }
    }
}

struct InfoBadge: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
        .foregroundColor(.white)
    }
}

struct IdeaCardCompact: View {
    let idea: BusinessIdea
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(idea.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Badge(idea.category, color: .yellow)
                Badge(idea.difficulty, color: .orange)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct Badge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.3))
            .cornerRadius(6)
            .foregroundColor(color)
    }
}

#Preview {
    QuizView()
}
