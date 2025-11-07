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
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Animated Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Step \(stepProgress()) of 5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int((Double(stepProgress()) / 5.0) * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.primaryOrange)
                    }
                    .padding(.horizontal, 24)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.primaryGradient)
                                .frame(width: geometry.size.width * (Double(stepProgress()) / 5.0), height: 8)
                                .animation(AnimationHelpers.smoothSpring, value: stepProgress())
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 16)
                
                // Content
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
                    .padding(24)
                }
                
                // Navigation Buttons
                VStack(spacing: 12) {
                    if viewModel.currentStep == .results {
                        PlayfulButton(
                            title: "Continue",
                            icon: "arrow.right.circle.fill",
                            gradient: AppColors.successGradient,
                            isLoading: viewModel.isLoading
                        ) {
                            completeQuiz()
                        }
                        .padding(.horizontal, 24)
                    } else if viewModel.currentStep != .loading {
                        HStack(spacing: 12) {
                            if viewModel.currentStep != .welcome {
                                Button {
                                    withAnimation(AnimationHelpers.buttonPress) {
                                        viewModel.previousStep()
                                    }
                                } label: {
                                    Text("Back")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(.systemGray6))
                                        )
                                }
                            }
                            
                            PlayfulButton(
                                title: "Next",
                                icon: "arrow.right.circle.fill",
                                gradient: AppColors.primaryGradient,
                                disabled: !canAdvance
                            ) {
                                withAnimation(AnimationHelpers.buttonPress) {
                                    viewModel.nextStep()
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
    @State private var animate = false
    
    var body: some View {
        ModernCard(padding: 32) {
            VStack(spacing: 24) {
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
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(AppColors.primaryGradient)
                        .scaleEffect(animate ? 1.1 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: animate
                        )
                }
                .bounceEntrance()
                
                Text("Let's Discover Your Perfect Business!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fadeInUp(delay: 0.2)
                
                Text("Answer a few quick questions and our AI will generate personalized business ideas tailored to your unique skills, personality, and interests.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fadeInUp(delay: 0.3)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct SkillsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What are your key skills?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("Select all that apply")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fadeInUp()
            
            if viewModel.isGeneratingOptions {
                ModernCard {
                    HStack {
                        ProgressView()
                            .tint(AppColors.primaryOrange)
                        Text("Generating options...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(Array(viewModel.allSkills.enumerated()), id: \.element) { index, skill in
                    SelectionChip(
                        text: skill,
                        isSelected: viewModel.selectedSkills.contains(skill),
                        color: AppColors.primaryOrange
                    ) {
                        withAnimation(AnimationHelpers.buttonPress) {
                            viewModel.toggleSkill(skill)
                        }
                        HapticManager.shared.trigger(viewModel.selectedSkills.contains(skill) ? .light : .medium)
                    }
                    .fadeInUp(delay: Double(index) * 0.05)
                }
            }
        }
    }
}

struct PersonalityStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Describe your personality")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("Choose traits that define you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fadeInUp()
            
            if viewModel.isGeneratingOptions {
                ModernCard {
                    HStack {
                        ProgressView()
                            .tint(AppColors.primaryOrange)
                        Text("Generating options...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(Array(viewModel.allPersonality.enumerated()), id: \.element) { index, trait in
                    SelectionChip(
                        text: trait,
                        isSelected: viewModel.selectedPersonality.contains(trait),
                        color: AppColors.primaryPink
                    ) {
                        withAnimation(AnimationHelpers.buttonPress) {
                            viewModel.togglePersonality(trait)
                        }
                        HapticManager.shared.trigger(viewModel.selectedPersonality.contains(trait) ? .light : .medium)
                    }
                    .fadeInUp(delay: Double(index) * 0.05)
                }
            }
        }
    }
}

struct InterestsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("What interests you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("Select your areas of interest")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .fadeInUp()
            
            if viewModel.isGeneratingOptions {
                ModernCard {
                    HStack {
                        ProgressView()
                            .tint(AppColors.primaryOrange)
                        Text("Generating options...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(Array(viewModel.allInterests.enumerated()), id: \.element) { index, interest in
                    SelectionChip(
                        text: interest,
                        isSelected: viewModel.selectedInterests.contains(interest),
                        color: AppColors.brightBlue
                    ) {
                        withAnimation(AnimationHelpers.buttonPress) {
                            viewModel.toggleInterest(interest)
                        }
                        HapticManager.shared.trigger(viewModel.selectedInterests.contains(interest) ? .light : .medium)
                    }
                    .fadeInUp(delay: Double(index) * 0.05)
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
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .fadeInUp()
            
            VStack(spacing: 16) {
                ModernTextField(
                    title: "First Name",
                    text: $firstName,
                    placeholder: "John",
                    icon: "person.fill"
                )
                .fadeInUp(delay: 0.1)
                
                ModernTextField(
                    title: "Last Name",
                    text: $lastName,
                    placeholder: "Doe",
                    icon: "person.fill"
                )
                .fadeInUp(delay: 0.2)
            }
        }
    }
}

struct LoadingStepView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ModernCard(padding: 40) {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.primaryOrange.opacity(0.3), AppColors.primaryPink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 8
                        )
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            AppColors.primaryGradient,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(rotation))
                        .animation(
                            Animation.linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                            value: rotation
                        )
                    
                    Image(systemName: "brain.head.profile")
                        .font(.title)
                        .foregroundStyle(AppColors.primaryGradient)
                }
                
                Text("AI is Thinking...")
                    .font(.title2.bold())
                
                Text("Google Gemini is analyzing your profile and generating personalized business ideas tailored just for you")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .onAppear {
            rotation = 360
        }
    }
}

struct ResultsStepView: View {
    @ObservedObject var viewModel: QuizViewModel
    @State private var celebrate = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.duolingoGreen.opacity(0.2), AppColors.successGreen.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.duolingoGreen)
                    .scaleEffect(celebrate ? 1.2 : 1.0)
                    .animation(AnimationHelpers.celebration, value: celebrate)
            }
            .bounceEntrance()
            
            Text("Profile Complete!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .fadeInUp(delay: 0.2)
            
            Text("Your personalized business dashboard is ready")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fadeInUp(delay: 0.3)
            
            if !viewModel.businessIdeas.isEmpty {
                ModernCard(padding: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Top Recommendations")
                            .font(.headline)
                        
                        ForEach(Array(viewModel.businessIdeas.prefix(3).enumerated()), id: \.element.id) { index, idea in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(idea.title)
                                        .font(.headline)
                                    Spacer()
                                    ColorfulBadge(idea.category, color: AppColors.primaryOrange)
                                }
                                
                                Text(idea.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray6))
                            )
                            .fadeInUp(delay: Double(index) * 0.1)
                        }
                    }
                }
                .fadeInUp(delay: 0.4)
            }
        }
        .onAppear {
            celebrate = true
            HapticManager.shared.trigger(.success)
        }
    }
}

// MARK: - Selection Chip
struct SelectionChip: View {
    let text: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? color : .secondary)
                
                Text(text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.15) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AnimationHelpers.buttonPress, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    QuizView()
}
