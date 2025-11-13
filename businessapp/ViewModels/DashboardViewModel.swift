import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    struct NutritionSummary {
        var goal: Int
        var consumed: Int
        var burned: Int
        var caloriesLeft: Int {
            max(goal - consumed + burned, 0)
        }
        var progress: Double {
            guard goal > 0 else { return 0 }
            return min(Double(consumed) / Double(goal), 1)
        }
    }
    
    struct MacroBreakdown: Identifiable {
        let id = UUID()
        let name: String
        let amountLeft: Int
        let goal: Int
        let unit: String
        let systemImage: String
    }
    
    struct MacroHighlight: Identifiable {
        let id = UUID()
        let label: String
        let value: String
        let systemImage: String
    }
    
    struct MealLog: Identifiable {
        let id = UUID()
        let title: String
        let time: Date
        let calories: Int
        let imageURL: URL?
        let macros: [MacroHighlight]
    }
    
    @Published var dailyGoals: [DailyGoal] = []
    @Published var milestones: [Milestone] = []
    @Published var selectedBusinessIdea: BusinessIdea?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var completionPercentage: Int = 0
    @Published var aiGeneratedGoals: [String] = []
    @Published var aiAdvice: String = ""
    @Published var isGeneratingAIContent = false
    @Published var nutritionSummary = NutritionSummary(goal: 2200, consumed: 461, burned: 0)
    @Published var macroBreakdown: [MacroBreakdown] = []
    @Published var recentMeals: [MealLog] = []
    
    private var userId: String?
    
    init(userId: String? = nil) {
        self.userId = userId
        prepareNutritionPreviewIfNeeded()
    }

    /// Attach the authenticated user's id so the view model can fetch/save data.
    func attachUser(userId: String) {
        self.userId = userId
    }
    
    // MARK: - AI-Powered Features
    
    func generateAIDailyGoals(for businessIdea: BusinessIdea) {
        isGeneratingAIContent = true
        
        GoogleAIService.shared.generateDailyGoals(
            businessIdea: businessIdea,
            currentProgress: completionPercentage
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingAIContent = false
                switch result {
                case .success(let goals):
                    self?.aiGeneratedGoals = goals
                    print("✅ Generated \(goals.count) AI-powered daily goals")
                case .failure(let error):
                    print("⚠️ Error generating goals: \(error.localizedDescription)")
                    self?.aiGeneratedGoals = [
                        "Research target market and validate demand",
                        "Create a minimum viable product (MVP) outline",
                        "Connect with 3 potential customers or mentors"
                    ]
                }
            }
        }
    }
    
    func getAIAdvice(context: String) {
        isGeneratingAIContent = true
        let currentGoals = dailyGoals.map { $0.title }
        
        GoogleAIService.shared.getPersonalizedAdvice(
            context: context,
            userGoals: currentGoals
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingAIContent = false
                switch result {
                case .success(let advice):
                    self?.aiAdvice = advice
                    print("✅ Received AI advice")
                case .failure(let error):
                    print("⚠️ Error getting advice: \(error.localizedDescription)")
                    self?.aiAdvice = "Focus on your most important goals first. Break down large tasks into smaller, manageable steps. Celebrate small wins along the way!"
                }
            }
        }
    }
    
    func addAIGoalToDashboard(_ goalTitle: String, businessIdeaId: String) {
        let goal = DailyGoal(
            id: UUID().uuidString,
            businessIdeaId: businessIdeaId,
            title: goalTitle,
            description: "AI-generated goal",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            completed: false,
            priority: "medium",
            createdAt: Date(),
            userId: userId ?? ""
        )
        addDailyGoal(goal)
    }
    
    func fetchDashboardData(businessIdeaId: String) {
        isLoading = true
        
        let group = DispatchGroup()
        
        group.enter()
        FirebaseService.shared.fetchDailyGoals(userId: userId ?? "") { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let goals):
                    self?.dailyGoals = goals
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                group.leave()
            }
        }
        
        group.enter()
        guard let userId = userId else {
            group.leave()
            return
        }
        FirebaseService.shared.fetchMilestones(userId: userId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let milestones):
                    self?.milestones = milestones
                    self?.calculateCompletion()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func addDailyGoal(_ goal: DailyGoal) {
        FirebaseService.shared.saveDailyGoal(goal) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dailyGoals.append(goal)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func addMilestone(_ milestone: Milestone) {
        FirebaseService.shared.saveMilestone(milestone) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.milestones.append(milestone)
                    self?.calculateCompletion()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func toggleGoalCompletion(_ goalId: String) {
        guard let userId = userId else { return }
        if let index = dailyGoals.firstIndex(where: { $0.id == goalId }) {
            let current = dailyGoals[index]
            let newCompleted = !current.completed
            // Update backend
            FirebaseService.shared.toggleGoalCompletion(goalId: goalId, completed: newCompleted, userId: userId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.dailyGoals[index].completed = newCompleted
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func toggleMilestoneCompletion(_ milestoneId: String) {
        guard let userId = userId else { return }
        if let index = milestones.firstIndex(where: { $0.id == milestoneId }) {
            let current = milestones[index]
            let newCompleted = !current.completed
            FirebaseService.shared.toggleMilestoneCompletion(milestoneId: milestoneId, completed: newCompleted, userId: userId) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.milestones[index].completed = newCompleted
                        self?.calculateCompletion()
                    case .failure(let error):
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func calculateCompletion() {
        let completedMilestones = milestones.filter { $0.completed }.count
        let total = milestones.count
        completionPercentage = total > 0 ? (completedMilestones * 100) / total : 0
    }
    
    var upcomingGoals: [DailyGoal] {
        dailyGoals.filter { !$0.completed && $0.dueDate > Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .prefix(5)
            .map { $0 }
    }
    
    var completedGoalsCount: Int {
        dailyGoals.filter { $0.completed }.count
    }
    
    func prepareNutritionPreviewIfNeeded() {
        // Removed demo data - will be populated from real backend
        guard macroBreakdown.isEmpty && recentMeals.isEmpty else { return }
        nutritionSummary = NutritionSummary(goal: 0, consumed: 0, burned: 0)
        macroBreakdown = []
        recentMeals = []
    }
    
    func bootstrapDemoData(for idea: BusinessIdea) {
        // Removed demo data - fetch from Firebase instead
        guard let userId = userId else { return }
        fetchDashboardData(businessIdeaId: idea.id)
    }
}
