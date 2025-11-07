import Foundation
import SwiftUI
import Combine

class QuizViewModel: ObservableObject {
    @Published var currentStep: QuizStep = .welcome
    @Published var selectedSkills: Set<String> = []
    @Published var selectedPersonality: Set<String> = []
    @Published var selectedInterests: Set<String> = []
    @Published var userProfile: UserProfile?
    @Published var businessIdeas: [BusinessIdea] = []
    @Published var isLoading = false
    @Published var aiGeneratedOptions: [String] = []
    @Published var isGeneratingOptions = false
    
    // Fallback options if AI fails
    let defaultSkills = [
        "Programming", "Data Analysis", "Design", "Marketing", "Sales",
        "Writing", "Public Speaking", "Project Management", "Finance", "Leadership"
    ]
    
    let defaultPersonality = [
        "Creative", "Analytical", "Organized", "Risk-Taker", "Networker",
        "Detail-Oriented", "Visionary", "Collaborative", "Independent", "Problem-Solver"
    ]
    
    let defaultInterests = [
        "Technology", "Business", "Fitness", "Education", "Entertainment",
        "Fashion", "Food", "Travel", "Real Estate", "Consulting"
    ]
    
    // Dynamic AI-powered options
    var allSkills: [String] {
        return aiGeneratedOptions.isEmpty ? defaultSkills : aiGeneratedOptions
    }
    
    var allPersonality: [String] {
        return aiGeneratedOptions.isEmpty ? defaultPersonality : aiGeneratedOptions
    }
    
    var allInterests: [String] {
        return aiGeneratedOptions.isEmpty ? defaultInterests : aiGeneratedOptions
    }
    
    enum QuizStep {
        case welcome
        case skills
        case personality
        case interests
        case personalInfo
        case loading
        case results
    }
    
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .skills
            loadAIOptionsForStep(1)
        case .skills:
            currentStep = .personality
            loadAIOptionsForStep(2)
        case .personality:
            currentStep = .interests
            loadAIOptionsForStep(3)
        case .interests:
            currentStep = .personalInfo
        case .personalInfo:
            generateIdeas()
        case .loading, .results:
            break
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .skills:
            currentStep = .welcome
        case .personality:
            currentStep = .skills
        case .interests:
            currentStep = .personality
        case .personalInfo:
            currentStep = .interests
        case .loading, .results:
            break
        }
    }
    
    func toggleSkill(_ skill: String) {
        if selectedSkills.contains(skill) {
            selectedSkills.remove(skill)
        } else {
            selectedSkills.insert(skill)
        }
    }
    
    func togglePersonality(_ trait: String) {
        if selectedPersonality.contains(trait) {
            selectedPersonality.remove(trait)
        } else {
            selectedPersonality.insert(trait)
        }
    }
    
    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
    
    // MARK: - AI-Powered Quiz Generation
    
    private func loadAIOptionsForStep(_ step: Int) {
        isGeneratingOptions = true
        
        var previousAnswers: [String: [String]] = [:]
        if step >= 2 {
            previousAnswers["skills"] = Array(selectedSkills)
        }
        if step >= 3 {
            previousAnswers["personality"] = Array(selectedPersonality)
        }
        
        GoogleAIService.shared.generateQuizQuestions(
            step: step,
            previousAnswers: previousAnswers
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingOptions = false
                switch result {
                case .success(let questions):
                    if let firstQuestion = questions.first {
                        self?.aiGeneratedOptions = firstQuestion.options
                    }
                case .failure(let error):
                    print("Error generating quiz options: \(error)")
                    // Fallback to default options
                    self?.aiGeneratedOptions = []
                }
            }
        }
    }
    
    private func generateIdeas() {
        currentStep = .loading
        isLoading = true
        let skills = Array(selectedSkills)
        let personality = Array(selectedPersonality)
        let interests = Array(selectedInterests)
        
        // Track quiz completion
        UserContextManager.shared.trackEvent(.quizCompleted, context: [
            "skillsCount": String(skills.count),
            "personalityCount": String(personality.count),
            "interestsCount": String(interests.count),
            "selectedSkills": skills.joined(separator: ", "),
            "selectedPersonality": personality.joined(separator: ", "),
            "selectedInterests": interests.joined(separator: ", ")
        ])
        
        GoogleAIService.shared.generateBusinessIdeas(
            skills: skills,
            personality: personality,
            interests: interests
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.currentStep = .results
                switch result {
                case .success(let ideas):
                    self?.businessIdeas = ideas
                    print("✅ Generated \(ideas.count) AI-powered business ideas")
                    
                    // Track successful idea generation
                    UserContextManager.shared.trackEvent(.businessIdeasGenerated, context: [
                        "ideasCount": String(ideas.count),
                        "categories": Set(ideas.map { $0.category }).joined(separator: ", ")
                    ])
                    
                case .failure(let error):
                    print("⚠️ Error generating ideas: \(error.localizedDescription)")
                    self?.businessIdeas = []
                    
                    // Track idea generation failure
                    UserContextManager.shared.trackEvent(.aiInteractionFailed, context: [
                        "interactionType": "business_idea_generation",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }

    static func fallbackIdeas(for userId: String, skills: [String], personality: [String], interests: [String]) -> [BusinessIdea] {
        let primarySkill = skills.first ?? "Strategic Planning"
        let supportingSkill = skills.dropFirst().first ?? "Brand Storytelling"
        let leadingInterest = interests.first ?? "Digital Products"
        let secondaryInterest = interests.dropFirst().first ?? "Community Building"
        let headlineTrait = personality.first ?? "Visionary"
        let secondaryTrait = personality.dropFirst().first ?? "Analytical"
        let now = Date()
        
        func category(for interest: String) -> String {
            let lower = interest.lowercased()
            if lower.contains("tech") || lower.contains("digital") { return "Technology" }
            if lower.contains("marketing") || lower.contains("branding") { return "Marketing" }
            if lower.contains("education") || lower.contains("learning") { return "Education" }
            if lower.contains("fitness") || lower.contains("wellness") { return "Health" }
            if lower.contains("food") || lower.contains("culinary") { return "Food" }
            if lower.contains("finance") { return "Finance" }
            return interest.isEmpty ? "General" : interest.capitalized
        }
        
        func requiredSkillsList(_ extra: [String]) -> [String] {
            let base = [primarySkill, supportingSkill] + extra
            return Array(Set(base.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }))
        }
        
        let studioIdea = BusinessIdea(
            id: UUID().uuidString,
            title: "\(leadingInterest) Launch Studio",
            description: "Build a boutique offering that packages your \(primarySkill.lowercased()) strength with a polished client experience around \(leadingInterest.lowercased()).",
            category: category(for: leadingInterest),
            difficulty: skills.count <= 1 ? "Easy" : "Medium",
            estimatedRevenue: "$45K - $120K / year",
            timeToLaunch: "6-10 weeks",
            requiredSkills: requiredSkillsList([]),
            startupCost: "$2K - $6K",
            profitMargin: "40-60%",
            marketDemand: "High",
            competition: "Medium",
            createdAt: now,
            userId: userId,
            personalizedNotes: "Your \(headlineTrait.lowercased()) mindset and \(primarySkill.lowercased()) expertise make it natural to lead premium \(leadingInterest.lowercased()) engagements."
        )
        
        let acceleratorIdea = BusinessIdea(
            id: UUID().uuidString,
            title: "\(secondaryInterest) Accelerator",
            description: "Design a guided, cohort-based program that helps learners master \(secondaryInterest.lowercased()) with actionable playbooks and live support.",
            category: category(for: secondaryInterest),
            difficulty: "Medium",
            estimatedRevenue: "$60K - $150K / year",
            timeToLaunch: "8-12 weeks",
            requiredSkills: requiredSkillsList(["Community Leadership", "Curriculum Design"]),
            startupCost: "$3K - $8K",
            profitMargin: "35-55%",
            marketDemand: "High",
            competition: "Low",
            createdAt: now,
            userId: userId,
            personalizedNotes: "Lean into your \(secondaryTrait.lowercased()) side to craft structured milestones while keeping sessions energized with your \(headlineTrait.lowercased()) presence."
        )
        
        let subscriptionIdea = BusinessIdea(
            id: UUID().uuidString,
            title: "Insight Library Subscription",
            description: "Launch a membership that delivers curated templates, tools, and AI-assisted prompts tailored to \(leadingInterest.lowercased()) creators every month.",
            category: "Subscription",
            difficulty: "Easy",
            estimatedRevenue: "$30K - $90K / year",
            timeToLaunch: "4-6 weeks",
            requiredSkills: requiredSkillsList(["Automation", "Content Strategy"]),
            startupCost: "$1K - $3K",
            profitMargin: "55-70%",
            marketDemand: "Medium",
            competition: "Medium",
            createdAt: now,
            userId: userId,
            personalizedNotes: "This recurring model keeps you close to customers while monetizing your ability to distill \(leadingInterest.lowercased()) trends fast."
        )
        
        return [studioIdea, acceleratorIdea, subscriptionIdea]
    }
}
