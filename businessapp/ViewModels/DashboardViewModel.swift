import Foundation
import SwiftUI
import Combine

class DashboardViewModel: ObservableObject {
    @Published var dailyGoals: [DailyGoal] = []
    @Published var milestones: [Milestone] = []
    @Published var selectedBusinessIdea: BusinessIdea?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var completionPercentage: Int = 0
    @Published var aiGeneratedGoals: [String] = []
    @Published var aiAdvice: String = ""
    @Published var isGeneratingAIContent = false
    
    private var userId: String?
    
    init(userId: String? = nil) {
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
        if let index = dailyGoals.firstIndex(where: { $0.id == goalId }) {
            let goal = dailyGoals[index]
            // In a real app, update Firebase here
            dailyGoals[index] = DailyGoal(
                id: goal.id,
                businessIdeaId: goal.businessIdeaId,
                title: goal.title,
                description: goal.description,
                dueDate: goal.dueDate,
                completed: !goal.completed,
                priority: goal.priority,
                createdAt: goal.createdAt,
                userId: goal.userId
            )
        }
    }
    
    func toggleMilestoneCompletion(_ milestoneId: String) {
        if let index = milestones.firstIndex(where: { $0.id == milestoneId }) {
            let milestone = milestones[index]
            milestones[index] = Milestone(
                id: milestone.id,
                businessIdeaId: milestone.businessIdeaId,
                title: milestone.title,
                description: milestone.description,
                dueDate: milestone.dueDate,
                completed: !milestone.completed,
                order: milestone.order,
                createdAt: milestone.createdAt,
                userId: milestone.userId
            )
            calculateCompletion()
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
    
    func bootstrapDemoData(for idea: BusinessIdea) {
        guard dailyGoals.isEmpty && milestones.isEmpty else { return }
        let today = Date()
        let userIdentifier = userId ?? idea.userId
        dailyGoals = [
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Interview 3 potential customers",
                description: "Validate the pain point and pricing assumptions",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: userIdentifier
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Draft the value proposition",
                description: "Summarize benefits for landing page copy",
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: today) ?? today,
                completed: false,
                priority: "Medium",
                createdAt: today,
                userId: userIdentifier
            )
        ]
        
        milestones = [
            Milestone(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Validate Problem",
                description: "Collect insights from 10 target users",
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: today) ?? today,
                completed: false,
                order: 1,
                createdAt: today,
                userId: userIdentifier
            ),
            Milestone(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Launch MVP",
                description: "Ship the first version to early adopters",
                dueDate: Calendar.current.date(byAdding: .day, value: 35, to: today) ?? today,
                completed: false,
                order: 2,
                createdAt: today,
                userId: userIdentifier
            )
        ]
        calculateCompletion()
    }
}
