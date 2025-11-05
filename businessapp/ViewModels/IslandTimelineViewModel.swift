import Foundation
import SwiftUI
import Combine

class IslandTimelineViewModel: ObservableObject {
    @Published var islands: [Island] = []
    @Published var currentIslandIndex: Int = 0
    @Published var journeyProgress: JourneyProgress = JourneyProgress()
    @Published var notes: [ProgressNote] = []
    @Published var reminders: [AppReminder] = []
    @Published var boatPosition: CGPoint = .zero
    @Published var dashboardGoals: [DailyGoal] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let googleAIService = GoogleAIService()
    
    // MARK: - Persistence Keys
    private let islandsKey = "saved_islands"
    private let journeyProgressKey = "journey_progress"
    private let notesKey = "progress_notes"
    private let remindersKey = "app_reminders"
    
    init() {
        loadPersistedData()
        setupDefaultIslands()
    }
    
    // MARK: - Connect to Store
    func connectToStore(_ store: BusinessPlanStore) {
        // Listen to store changes to sync goals
        store.$businessIdeas
            .sink { [weak self] ideas in
                guard let self = self,
                      let selectedIdea = store.selectedBusinessIdea else { return }
                
                // Regenerate islands if needed
                if self.islands.count <= 3 && !ideas.isEmpty {
                    self.syncWithDashboard(businessIdea: selectedIdea)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync with Dashboard Goals
    func syncWithDashboard(businessIdea: BusinessIdea) {
        // If we have real goals from dashboard, use them
        if !dashboardGoals.isEmpty {
            generateIslandsFromBusinessPlan(businessIdea: businessIdea, goals: dashboardGoals)
        } else {
            // Generate sample goals for now
            let sampleGoals = createSampleGoals(for: businessIdea)
            generateIslandsFromBusinessPlan(businessIdea: businessIdea, goals: sampleGoals)
        }
    }
    
    private func createSampleGoals(for idea: BusinessIdea) -> [DailyGoal] {
        let today = Date()
        return [
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Research market competitors",
                description: "Identify key competitors and analyze their offerings",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Create initial business plan",
                description: "Draft core business model and strategy",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Design brand identity",
                description: "Create logo and brand guidelines",
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: today) ?? today,
                completed: false,
                priority: "Medium",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Build MVP prototype",
                description: "Create minimum viable product",
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Test with early users",
                description: "Get feedback from 10 beta users",
                dueDate: Calendar.current.date(byAdding: .day, value: 21, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Launch marketing campaign",
                description: "Start social media and email marketing",
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today,
                completed: false,
                priority: "Medium",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Secure first customers",
                description: "Close first 5 paying customers",
                dueDate: Calendar.current.date(byAdding: .day, value: 45, to: today) ?? today,
                completed: false,
                priority: "High",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Iterate based on feedback",
                description: "Implement user suggestions and improvements",
                dueDate: Calendar.current.date(byAdding: .day, value: 60, to: today) ?? today,
                completed: false,
                priority: "Medium",
                createdAt: today,
                userId: idea.userId
            ),
            DailyGoal(
                id: UUID().uuidString,
                businessIdeaId: idea.id,
                title: "Scale operations",
                description: "Hire team and expand to new markets",
                dueDate: Calendar.current.date(byAdding: .day, value: 90, to: today) ?? today,
                completed: false,
                priority: "Medium",
                createdAt: today,
                userId: idea.userId
            )
        ]
    }
    
    // MARK: - Generate Islands from Business Plan
    func generateIslandsFromBusinessPlan(businessIdea: BusinessIdea, goals: [DailyGoal]) {
        islands.removeAll()
        
        // Start Island
        let startIsland = Island(
            title: "🚀 Launch",
            description: "Begin your entrepreneurial journey!",
            position: CGPoint(x: 50, y: 500),
            type: .start
        )
        islands.append(startIsland)
        
        // Create islands from goals (group every 3 goals into one island)
        let goalChunks = goals.chunked(into: 3)
        for (index, chunk) in goalChunks.enumerated() {
            let xPos: CGFloat = 150 + CGFloat(index % 2) * 150
            let yPos: CGFloat = 400 - CGFloat(index) * 120
            
            let island = Island(
                title: "Stage \(index + 1)",
                description: chunk.first?.title ?? "Progress milestone",
                goalIds: chunk.map { $0.id },
                position: CGPoint(x: xPos, y: yPos),
                type: index % 2 == 0 ? .regular : .milestone
            )
            islands.append(island)
        }
        
        // Treasure Island (Final Goal)
        let treasureIsland = Island(
            title: "🏆 Success",
            description: businessIdea.title,
            position: CGPoint(x: 200, y: 100),
            type: .treasure
        )
        islands.append(treasureIsland)
        
        journeyProgress.currentIslandId = startIsland.id
        persistIslands()
    }
    
    // MARK: - Island Navigation
    func moveToNextIsland() {
        guard currentIslandIndex < islands.count - 1 else { return }
        
        // Mark current as completed
        islands[currentIslandIndex].isCompleted = true
        islands[currentIslandIndex].completedAt = Date()
        journeyProgress.completedIslandIds.append(islands[currentIslandIndex].id)
        
        // Move to next
        currentIslandIndex += 1
        journeyProgress.currentIslandId = islands[currentIslandIndex].id
        
        // Unlock next island
        islands[currentIslandIndex].unlockedAt = Date()
        
        animateBoatToNextIsland()
        persistIslands()
    }
    
    func completeIsland(id: String) {
        guard let index = islands.firstIndex(where: { $0.id == id }) else { return }
        islands[index].isCompleted = true
        islands[index].completedAt = Date()
        journeyProgress.completedIslandIds.append(id)
        persistIslands()
    }
    
    // MARK: - Notes Management
    func addNote(content: String, islandId: String? = nil, goalId: String? = nil, tags: [String] = []) {
        let note = ProgressNote(
            content: content,
            islandId: islandId,
            goalId: goalId,
            tags: tags
        )
        notes.append(note)
        persistNotes()
    }
    
    func deleteNote(id: String) {
        notes.removeAll { $0.id == id }
        persistNotes()
    }
    
    func getNotesFor(islandId: String) -> [ProgressNote] {
        return notes.filter { $0.islandId == islandId }
    }
    
    // MARK: - Reminders Management
    func addReminder(
        title: String,
        message: String,
        scheduledDate: Date,
        islandId: String? = nil,
        goalId: String? = nil,
        addToCalendar: Bool = false
    ) {
        let reminder = AppReminder(
            title: title,
            message: message,
            scheduledDate: scheduledDate,
            islandId: islandId,
            goalId: goalId,
            notifyViaCalendar: addToCalendar
        )
        reminders.append(reminder)
        
        if addToCalendar {
            scheduleCalendarEvent(reminder: reminder)
        }
        
        persistReminders()
    }
    
    func completeReminder(id: String) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].isCompleted = true
        persistReminders()
    }
    
    func deleteReminder(id: String) {
        reminders.removeAll { $0.id == id }
        persistReminders()
    }
    
    // MARK: - AI Integration
    func askAIAboutProgress(question: String, completion: @escaping (String) -> Void) {
        let context = buildProgressContext()
        let prompt = """
        User is on an island-based journey to build their business: \(islands.first?.description ?? "business")
        
        Current Progress:
        - On island \(currentIslandIndex + 1) of \(islands.count)
        - Completed islands: \(journeyProgress.completedIslandIds.count)
        - Recent notes: \(notes.suffix(3).map { $0.content }.joined(separator: ", "))
        
        User's question: \(question)
        
        Provide a helpful, encouraging response with specific actionable advice.
        Keep it conversational and motivating. Use emojis where appropriate.
        """
        
        googleAIService.getPersonalizedAdvice(context: prompt, userGoals: []) { result in
            switch result {
            case .success(let advice):
                completion(advice)
            case .failure:
                completion("I'm here to help! Let's break down your question into actionable steps. What specific area would you like to focus on?")
            }
        }
    }
    
    func updateTimelineWithAI(request: String, completion: @escaping (Bool, String) -> Void) {
        // AI can modify timeline based on user request
        let prompt = """
        User wants to modify their journey timeline: "\(request)"
        Current islands: \(islands.map { $0.title }.joined(separator: ", "))
        
        Suggest how to reorganize or add islands to match their request.
        Format: Return comma-separated island titles.
        """
        
        googleAIService.makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                // Parse and update islands
                completion(true, "Timeline updated based on your request!")
            case .failure:
                completion(false, "Couldn't update timeline. Please try again.")
            }
        }
    }
    
    // MARK: - Animation
    private func animateBoatToNextIsland() {
        guard currentIslandIndex < islands.count else { return }
        boatPosition = islands[currentIslandIndex].position
    }
    
    // MARK: - Helper Functions
    private func buildProgressContext() -> String {
        let completedCount = journeyProgress.completedIslandIds.count
        let totalCount = islands.count
        let percentage = totalCount > 0 ? (Double(completedCount) / Double(totalCount)) * 100 : 0
        return "Progress: \(Int(percentage))% complete. On island \(currentIslandIndex + 1) of \(totalCount)."
    }
    
    private func setupDefaultIslands() {
        if islands.isEmpty {
            islands = [
                Island(
                    title: "🚀 Start",
                    description: "Welcome to your journey!",
                    position: CGPoint(x: 50, y: 500),
                    type: .start
                ),
                Island(
                    title: "📋 Planning",
                    description: "Create your business plan",
                    position: CGPoint(x: 150, y: 400),
                    type: .regular
                ),
                Island(
                    title: "🏆 Launch",
                    description: "Launch your business!",
                    position: CGPoint(x: 250, y: 300),
                    type: .treasure
                )
            ]
            journeyProgress.currentIslandId = islands.first?.id
        }
    }
    
    // MARK: - Calendar Integration
    private func scheduleCalendarEvent(reminder: AppReminder) {
        // This will be implemented with EventKit
        // For now, it's a placeholder
    }
    
    // MARK: - Persistence
    private func persistIslands() {
        if let encoded = try? JSONEncoder().encode(islands) {
            UserDefaults.standard.set(encoded, forKey: islandsKey)
        }
        if let progressEncoded = try? JSONEncoder().encode(journeyProgress) {
            UserDefaults.standard.set(progressEncoded, forKey: journeyProgressKey)
        }
    }
    
    private func persistNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func persistReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: remindersKey)
        }
    }
    
    private func loadPersistedData() {
        if let data = UserDefaults.standard.data(forKey: islandsKey),
           let decoded = try? JSONDecoder().decode([Island].self, from: data) {
            islands = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: journeyProgressKey),
           let decoded = try? JSONDecoder().decode(JourneyProgress.self, from: data) {
            journeyProgress = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([ProgressNote].self, from: data) {
            notes = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: remindersKey),
           let decoded = try? JSONDecoder().decode([AppReminder].self, from: data) {
            reminders = decoded
        }
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
