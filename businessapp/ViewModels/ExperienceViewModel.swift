import Foundation
import Combine
import SwiftUI
import FirebaseCrashlytics

@MainActor
final class ExperienceViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @Published private(set) var dailyGoals: [DailyGoal] = []
    @Published private(set) var milestones: [Milestone] = []
    @Published private(set) var reminders: [AppReminder] = []
    @Published private(set) var notes: [ProgressNote] = []
    @Published private(set) var journeyProgress: JourneyProgress = JourneyProgress()
    @Published private(set) var islands: [Island] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firebase = FirebaseService.shared
    private var userId: String?
    private var businessIdeaId: String? {
        store?.selectedBusinessIdea?.id
    }
    private weak var store: BusinessPlanStore?
    
    func attach(store: BusinessPlanStore, userId: String) {
        self.store = store
        self.userId = userId
        Task {
            await refresh()
        }
    }
    
    func refresh() async {
        guard let userId else { return }
        isLoading = true
        errorMessage = nil
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadGoals(userId: userId) }
            group.addTask { await self.loadMilestones(userId: userId) }
            group.addTask { await self.loadReminders(userId: userId) }
            group.addTask { await self.loadNotes(userId: userId) }
            group.addTask { await self.loadJourney(userId: userId) }
        }
        isLoading = false
    }
    
    // MARK: - Actions
    func addGoal(title: String, description: String, dueDate: Date, priority: String) {
        guard let userId else { return }
        let goal = DailyGoal(
            id: UUID().uuidString,
            businessIdeaId: businessIdeaId ?? "",
            title: title,
            description: description,
            dueDate: dueDate,
            completed: false,
            priority: priority,
            createdAt: Date(),
            userId: userId
        )
        FirebaseService.shared.saveDailyGoal(goal) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Task { await self.loadGoals(userId: userId) }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleGoalCompletion(_ goal: DailyGoal) {
        guard let userId else { return }
        Task {
            do {
                let newCompletionStatus = !goal.completed
                try await firebase.toggleGoalCompletion(userId: userId, goalId: goal.id, completed: newCompletionStatus)
                
                // Haptic feedback
                if newCompletionStatus {
                    HapticManager.shared.successRhythm()
                } else {
                    HapticManager.shared.trigger(.light)
                }
                
                // Track goal completion event
                if newCompletionStatus {
                    UserContextManager.shared.trackEvent(.goalCompleted, context: [
                        "goalId": goal.id,
                        "title": goal.title,
                        "priority": goal.priority,
                        "daysToComplete": String(Calendar.current.dateComponents([.day], from: goal.createdAt, to: Date()).day ?? 0)
                    ])
                } else {
                    UserContextManager.shared.trackEvent(.goalReopened, context: [
                        "goalId": goal.id,
                        "title": goal.title
                    ])
                }
                
                await loadGoals(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func addMilestone(title: String, description: String, dueDate: Date) {
        guard let userId else { return }
        let milestone = Milestone(
            id: UUID().uuidString,
            businessIdeaId: businessIdeaId ?? "",
            title: title,
            description: description,
            dueDate: dueDate,
            completed: false,
            order: milestones.count + 1,
            createdAt: Date(),
            userId: userId
        )
        firebase.saveMilestone(milestone) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Task { await self.loadMilestones(userId: userId) }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func toggleMilestone(_ milestone: Milestone) {
        guard let userId else { return }
        Task {
            do {
                try await firebase.toggleMilestoneCompletion(userId: userId, milestoneId: milestone.id, completed: !milestone.completed)
                await loadMilestones(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func addReminder(title: String, message: String, scheduled: Date, islandId: String? = nil) {
        guard let userId else { return }
        let reminder = AppReminder(
            title: title,
            message: message,
            scheduledDate: scheduled,
            islandId: islandId
        )
        firebase.saveReminder(reminder) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Task { await self.loadReminders(userId: userId) }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func addNote(content: String, islandId: String? = nil) {
        guard let userId else { return }
        let note = ProgressNote(content: content, islandId: islandId)
        firebase.saveNote(note) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Task { await self.loadNotes(userId: userId) }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Private loaders
    private func loadGoals(userId: String) async {
        do {
            let goals = try await firebase.fetchDailyGoals(userId: userId)
            await MainActor.run { self.dailyGoals = goals }
        } catch {
            await handle(error: error)
        }
    }
    
    private func loadMilestones(userId: String) async {
        do {
            let milestones = try await firebase.fetchMilestones(userId: userId)
            await MainActor.run { self.milestones = milestones }
        } catch {
            await handle(error: error)
        }
    }
    
    private func loadReminders(userId: String) async {
        do {
            let reminders = try await firebase.fetchReminders(userId: userId)
            await MainActor.run { self.reminders = reminders }
        } catch {
            await handle(error: error)
        }
    }
    
    private func loadNotes(userId: String) async {
        do {
            let notes = try await firebase.fetchNotes(userId: userId)
            await MainActor.run { self.notes = notes }
        } catch {
            await handle(error: error)
        }
    }
    
    private func loadJourney(userId: String) async {
        do {
            let result = try await firebase.fetchJourney(userId: userId)
            await MainActor.run {
                self.journeyProgress = result.progress
                self.islands = result.islands
            }
        } catch {
            await handle(error: error)
        }
    }
    
    private func handle(error: Error) async {
        Crashlytics.crashlytics().record(error: error)
        await MainActor.run {
            self.errorMessage = error.localizedDescription
        }
    }
}
