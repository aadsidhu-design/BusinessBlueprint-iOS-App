import Foundation
import FirebaseFirestore
import Combine

// MARK: - User Context Manager

@MainActor
class UserContextManager: ObservableObject {
    static let shared = UserContextManager()
    
    @Published var userContext: UserContext?
    @Published var isLoading = false
    @Published var error: ContextError?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var contextUpdateTimer: Timer?
    
    private init() {
        setupAutoSave()
    }
    
    deinit {
        contextUpdateTimer?.invalidate()
    }
    
    // MARK: - Context Initialization
    
    func initializeContext(userId: String, profile: UserProfile) async {
        isLoading = true
        
        do {
            // Try to load existing context
            if let existingContext = try await loadContext(userId: userId) {
                userContext = existingContext
            } else {
                // Create new context
                let newContext = UserContext(userId: userId, profile: profile)
                userContext = newContext
                try await saveContext()
            }
            
            startContextTracking()
            error = nil
        } catch {
            self.error = ContextError.loadingFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    // MARK: - Context Loading & Saving
    
    private func loadContext(userId: String) async throws -> UserContext? {
        // Organized structure: users/{userId}/context/{contextId}
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("context")
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        
        let data = try JSONSerialization.data(withJSONObject: document.data())
        return try JSONDecoder().decode(UserContext.self, from: data)
    }
    
    private func saveContext() async throws {
        guard let context = userContext else { return }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(context)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        // Organized structure: users/{userId}/context/{contextId}
        try await db.collection("users")
            .document(context.userId)
            .collection("context")
            .document(context.id)
            .setData(dictionary)
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ eventType: InteractionEvent.EventType, 
                   context: [String: String] = [:], 
                   outcome: InteractionEvent.EventOutcome? = nil) {
        guard var userContext = userContext else { return }
        
        let event = InteractionEvent(type: eventType, context: context, outcome: outcome)
        userContext.interactionHistory.append(event)
        
        // Keep only last 1000 events
        if userContext.interactionHistory.count > 1000 {
            userContext.interactionHistory.removeFirst(100)
        }
        
        updateBehaviorPatterns(with: event)
        updateGoalPatterns(with: event)
        updateDecisionPatterns(with: event)
        updateBusinessJourney(with: event)
        
        userContext.lastUpdated = Date()
        self.userContext = userContext
    }
    
    func trackAIConversation(userQuery: String, aiResponse: String, context: String, topics: [String] = []) {
        guard var userContext = userContext else { return }
        
        let conversation = AIConversation(
            userQuery: userQuery,
            aiResponse: aiResponse,
            context: context,
            topics: topics
        )
        
        userContext.aiContext.conversationHistory.append(conversation)
        
        // Analyze conversation for insights
        analyzeConversationPatterns(conversation: conversation)
        
        // Keep only last 200 conversations
        if userContext.aiContext.conversationHistory.count > 200 {
            userContext.aiContext.conversationHistory.removeFirst(50)
        }
        
        userContext.lastUpdated = Date()
        self.userContext = userContext
    }
    
    func trackGoalCreation(goal: DailyGoal) {
        trackEvent(.goalCreated, context: [
            "title": goal.title,
            "priority": goal.priority,
            "category": goal.description.isEmpty ? "simple" : "detailed"
        ])
        
        // Update goal patterns
        guard var userContext = userContext else { return }
        userContext.goalPatterns.goalCreationFrequency = calculateGoalFrequency()
        updateGoalComplexityPreference(for: goal)
        self.userContext = userContext
    }
    
    func trackGoalCompletion(goal: DailyGoal, completionTime: TimeInterval) {
        trackEvent(.goalCompleted, context: [
            "title": goal.title,
            "completionTime": String(completionTime),
            "priority": goal.priority
        ], outcome: .successful)
        
        updateGoalCompletionRate()
        updateAverageGoalDuration(completionTime)
    }
    
    func trackBusinessIdeaInteraction(idea: BusinessIdea, action: String) {
        let eventType: InteractionEvent.EventType = {
            switch action {
            case "viewed": return .ideaViewed
            case "favorited": return .ideaFavorited
            case "selected": return .ideaSelected
            default: return .ideaViewed
            }
        }()
        
        trackEvent(eventType, context: [
            "ideaTitle": idea.title,
            "category": idea.category,
            "difficulty": idea.difficulty,
            "action": action
        ])
        
        updateBusinessJourneyProgress(with: idea, action: action)
    }
    
    // MARK: - Context Analysis
    
    private func updateBehaviorPatterns(with event: InteractionEvent) {
        guard var userContext = userContext else { return }
        
        let hour = Calendar.current.component(.hour, from: event.timestamp)
        let weekday = Calendar.current.component(.weekday, from: event.timestamp)
        
        // Update activity patterns
        userContext.behaviorPatterns.dailyActivityPattern[hour, default: 0] += 1
        userContext.behaviorPatterns.weeklyActivityPattern[weekday, default: 0] += 1
        
        // Update feature usage
        let featureName = event.eventType.rawValue
        userContext.behaviorPatterns.featureUsage[featureName, default: 0] += 1
        
        // Update engagement level
        updateEngagementLevel()
        
        self.userContext = userContext
    }
    
    private func updateGoalPatterns(with event: InteractionEvent) {
        guard var userContext = userContext else { return }
        
        switch event.eventType {
        case .goalCompleted:
            userContext.goalPatterns.goalCompletionRate = calculateGoalCompletionRate()
        case .goalAbandoned:
            if let reason = event.context["reason"] {
                userContext.goalPatterns.goalAbandonmentReasons[reason, default: 0] += 1
            }
        default:
            break
        }
        
        self.userContext = userContext
    }
    
    private func updateDecisionPatterns(with event: InteractionEvent) {
        guard var userContext = userContext else { return }
        
        // Analyze decision speed based on time between events
        let recentEvents = userContext.interactionHistory.suffix(5)
        if recentEvents.count > 1 {
            let timeDifferences = zip(recentEvents, recentEvents.dropFirst()).map { 
                $0.1.timestamp.timeIntervalSince($0.0.timestamp) 
            }
            let averageDecisionTime = timeDifferences.reduce(0, +) / Double(timeDifferences.count)
            
            userContext.decisionPatterns.decisionSpeed = classifyDecisionSpeed(averageTime: averageDecisionTime)
        }
        
        self.userContext = userContext
    }
    
    private func updateBusinessJourney(with event: InteractionEvent) {
        guard var userContext = userContext else { return }
        
        switch event.eventType {
        case .goalCompleted:
            let milestone = "Goal Achievement: \(event.context["title"] ?? "Unknown")"
            if !userContext.businessJourney.milestonesAchieved.contains(milestone) {
                userContext.businessJourney.milestonesAchieved.append(milestone)
            }
        case .ideaSelected:
            updateEntrepreneurshipStage()
        default:
            break
        }
        
        self.userContext = userContext
    }
    
    // MARK: - AI Context Enhancement
    
    private func addUserContextToPrompt(_ prompt: String) -> String {
        // TODO: Enhance this with more user-specific context
        return prompt
    }

    func enhanceAIPrompt(basePrompt: String, context: String) -> String {
        guard userContext != nil else { return basePrompt }
        
        var enhancedPrompt = basePrompt
        
        // Add user context enhancement
        enhancedPrompt = addUserContextToPrompt(enhancedPrompt)
        
        // Add user profile context
        let profileContext = buildProfileContext()
        enhancedPrompt += "\n\nUSER PROFILE CONTEXT:\n\(profileContext)"
        
        // Add behavioral insights
        let behaviorContext = buildBehaviorContext()
        enhancedPrompt += "\n\nBEHAVIOR INSIGHTS:\n\(behaviorContext)"
        
        return enhancedPrompt
    }
    
    func enhanceAIPrompt(basePrompt: String, context: String, businessIdea: BusinessIdea? = nil) -> String {
        guard userContext != nil else { return basePrompt }
        
        var enhancedPrompt = basePrompt
        
        // Add business idea context if provided
        if let idea = businessIdea {
            enhancedPrompt += """
            
            CURRENT BUSINESS FOCUS:
            • Title: \(idea.title)
            • Category: \(idea.category) 
            • Description: \(idea.description)
            • Difficulty: \(idea.difficulty)
            • Estimated Revenue: \(idea.estimatedRevenue)
            • Time to Launch: \(idea.timeToLaunch)
            """
        }
        
        // Add user context enhancement
        enhancedPrompt = addUserContextToPrompt(enhancedPrompt)
        
        // Add user profile context
        let profileContext = buildProfileContext()
        enhancedPrompt += "\n\nUSER PROFILE CONTEXT:\n\(profileContext)"
        
        // Add behavioral insights
        let behaviorContext = buildBehaviorContext()
        enhancedPrompt += "\n\nBEHAVIOR INSIGHTS:\n\(behaviorContext)"
        
        // Add goal patterns
        let goalContext = buildGoalContext()
        enhancedPrompt += "\n\nGOAL PATTERNS:\n\(goalContext)"
        
        // Add communication preferences
        let commContext = buildCommunicationContext()
        enhancedPrompt += "\n\nCOMMUNICATION STYLE:\n\(commContext)"
        
        return enhancedPrompt
    }
    
    private func buildProfileContext() -> String {
        guard let context = userContext else { return "" }
        
        return """
        • Stage: \(context.businessJourney.currentStage.rawValue)
        • Skills: \(context.skillsEvolution.currentSkills.joined(separator: ", "))
        • Personality: \(context.personalityInsights.baseTraits.joined(separator: ", "))
        • Working Style: \(context.personalityInsights.workingStyle.rawValue)
        • Engagement Level: \(context.behaviorPatterns.engagementLevel.description)
        """
    }
    
    private func buildBehaviorContext() -> String {
        guard let context = userContext else { return "" }
        
        let topFeatures = context.behaviorPatterns.featureUsage
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return """
        • Most Used Features: \(topFeatures.joined(separator: ", "))
        • Decision Speed: \(context.decisionPatterns.decisionSpeed.rawValue)
        • Risk Tolerance: \(context.decisionPatterns.riskTolerance.rawValue)
        • Goal Completion Rate: \(Int(context.goalPatterns.goalCompletionRate * 100))%
        """
    }
    
    private func buildGoalContext() -> String {
        guard let context = userContext else { return "" }
        
        return """
        • Goal Creation Frequency: \(String(format: "%.1f", context.goalPatterns.goalCreationFrequency)) per week
        • Complexity Preference: \(context.goalPatterns.goalComplexityPreference.rawValue)
        • Preferred Types: \(context.goalPatterns.preferredGoalTypes.joined(separator: ", "))
        """
    }
    
    private func buildCommunicationContext() -> String {
        guard let context = userContext else { return "" }
        
        return """
        • Preferred Tone: \(context.communicationStyle.preferredTone.rawValue)
        • Detail Level: \(context.communicationStyle.detailPreference.rawValue)
        • Encouragement Style: \(context.communicationStyle.encouragementStyle.rawValue)
        • Information Depth: \(context.decisionPatterns.preferredInformationDepth.rawValue)
        """
    }
    
    // MARK: - Helper Methods
    
    private func calculateGoalFrequency() -> Double {
        guard let context = userContext else { return 0 }
        
        let goalEvents = context.interactionHistory.filter { $0.eventType == .goalCreated }
        let weeksActive = max(1, Date().timeIntervalSince(context.createdAt) / (7 * 24 * 3600))
        
        return Double(goalEvents.count) / weeksActive
    }
    
    private func calculateGoalCompletionRate() -> Double {
        guard let context = userContext else { return 0 }
        
        let completedGoals = context.interactionHistory.filter { $0.eventType == .goalCompleted }.count
        let totalGoals = context.interactionHistory.filter { $0.eventType == .goalCreated }.count
        
        guard totalGoals > 0 else { return 0 }
        return Double(completedGoals) / Double(totalGoals)
    }
    
    private func updateGoalCompletionRate() {
        guard var context = userContext else { return }
        context.goalPatterns.goalCompletionRate = calculateGoalCompletionRate()
        userContext = context
    }
    
    private func updateAverageGoalDuration(_ newDuration: TimeInterval) {
        guard var context = userContext else { return }
        
        let currentAverage = context.goalPatterns.averageGoalDuration
        let completedGoals = context.interactionHistory.filter { $0.eventType == .goalCompleted }.count
        
        if completedGoals <= 1 {
            context.goalPatterns.averageGoalDuration = newDuration
        } else {
            // Running average
            context.goalPatterns.averageGoalDuration = 
                (currentAverage * Double(completedGoals - 1) + newDuration) / Double(completedGoals)
        }
        
        userContext = context
    }
    
    private func updateEngagementLevel() {
        guard var context = userContext else { return }
        
        let recentEvents = context.interactionHistory.suffix(50)
        let dailyEvents = recentEvents.count / 7 // Approximate daily events
        
        context.behaviorPatterns.engagementLevel = {
            switch dailyEvents {
            case 0...2: return .low
            case 3...7: return .medium
            case 8...15: return .high
            default: return .veryHigh
            }
        }()
        
        userContext = context
    }
    
    private func classifyDecisionSpeed(averageTime: TimeInterval) -> DecisionPatterns.DecisionSpeed {
        switch averageTime {
        case 0...30: return .quick
        case 31...120: return .moderate
        case 121...300: return .deliberate
        default: return .thorough
        }
    }
    
    private func updateEntrepreneurshipStage() {
        guard var context = userContext else { return }
        
        let milestonesCount = context.businessJourney.milestonesAchieved.count
        let currentStage = context.businessJourney.currentStage
        
        let suggestedStage: BusinessJourney.EntrepreneurshipStage = {
            switch milestonesCount {
            case 0...2: return .exploring
            case 3...5: return .validating
            case 6...10: return .planning
            case 11...20: return .launching
            case 21...35: return .growing
            case 36...50: return .scaling
            default: return .established
            }
        }()
        
        // Only advance, don't regress
        if suggestedStage.rawValue > currentStage.rawValue {
            context.businessJourney.currentStage = suggestedStage
            userContext = context
        }
    }
    
    private func updateGoalComplexityPreference(for goal: DailyGoal) {
        guard var context = userContext else { return }
        
        let complexity: GoalPatterns.ComplexityLevel = {
            if goal.description.count > 100 {
                return .complex
            } else if goal.description.count > 50 {
                return .medium
            } else if goal.description.isEmpty {
                return .simple
            } else {
                return .medium
            }
        }()
        
        // Track preference over time
        context.goalPatterns.goalComplexityPreference = complexity
        userContext = context
    }
    
    private func updateBusinessJourneyProgress(with idea: BusinessIdea, action: String) {
        guard var context = userContext else { return }
        
        if action == "selected" {
            let industryExp = context.businessJourney.industryExperience[idea.category] ?? .none
            if industryExp == .none {
                context.businessJourney.industryExperience[idea.category] = .basic
            }
        }
        
        userContext = context
    }
    
    private func analyzeConversationPatterns(conversation: AIConversation) {
        guard var context = userContext else { return }
        
        // Update topic expertise
        for topic in conversation.topics {
            context.aiContext.topicExpertise[topic, default: 0] += 0.1
        }
        
        // Analyze question patterns
        let questionWords = ["how", "what", "when", "where", "why", "can", "should", "will"]
        for word in questionWords {
            if conversation.userQuery.lowercased().contains(word) {
                context.aiContext.questionPatterns.append(word)
                // Keep only last 100 patterns
                if context.aiContext.questionPatterns.count > 100 {
                    context.aiContext.questionPatterns.removeFirst()
                }
            }
        }
        
        userContext = context
    }
    
    // MARK: - Auto-save Setup
    
    private func setupAutoSave() {
        contextUpdateTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                try? await self.saveContext()
            }
        }
    }
    
    private func startContextTracking() {
        trackEvent(.sessionStarted, context: ["timestamp": ISO8601DateFormatter().string(from: Date())])
    }
    
    func endSession() {
        trackEvent(.sessionEnded, context: ["duration": String(Date().timeIntervalSince(Date()))])
        
        Task {
            try? await saveContext()
        }
    }
}

// MARK: - Context Error

enum ContextError: LocalizedError {
    case loadingFailed(String)
    case savingFailed(String)
    case invalidData
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .loadingFailed(let message):
            return "Failed to load user context: \(message)"
        case .savingFailed(let message):
            return "Failed to save user context: \(message)"
        case .invalidData:
            return "Invalid context data format"
        case .userNotFound:
            return "User context not found"
        }
    }
}