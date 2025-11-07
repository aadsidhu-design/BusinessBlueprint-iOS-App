import Foundation
import Combine
import FirebaseFirestore
import FirebaseCrashlytics

// MARK: - Context Action Types
enum ContextAction: Codable {
    case aiConversation(message: String, response: String)
    case noteCreated(content: String, category: String?)
    case reminderSet(title: String, date: Date, type: ReminderType)
    case businessIdeaExplored(idea: String, industry: String?)
    case timelineInteraction(action: TimelineAction, details: String?)
    case goalSet(title: String, deadline: Date?, priority: Priority)
    case milestoneCompleted(title: String, progress: Double)
    case exportedToCalendar(items: [String])
    case searchPerformed(query: String, results: Int)
    case settingsChanged(setting: String, newValue: String)
    
    var actionType: String {
        switch self {
        case .aiConversation: return "ai_conversation"
        case .noteCreated: return "note_created"
        case .reminderSet: return "reminder_set"
        case .businessIdeaExplored: return "business_idea_explored"
        case .timelineInteraction: return "timeline_interaction"
        case .goalSet: return "goal_set"
        case .milestoneCompleted: return "milestone_completed"
        case .exportedToCalendar: return "exported_to_calendar"
        case .searchPerformed: return "search_performed"
        case .settingsChanged: return "settings_changed"
        }
    }
}

enum TimelineAction: Codable {
    case stageModified, orderChanged, itemAdded, itemRemoved, progressUpdated
}

enum ReminderType: String, Codable {
    case meeting = "meeting"
    case deadline = "deadline" 
    case followup = "followup"
    case milestone = "milestone"
    case custom = "custom"
}

enum Priority: String, Codable {
    case low = "low"
    case medium = "medium" 
    case high = "high"
    case critical = "critical"
}

// MARK: - Context Entry
struct ContextEntry: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let action: ContextAction
    let sessionId: String
    let businessIdeaId: String?
    let metadata: [String: String]
    
    init(action: ContextAction, businessIdeaId: String? = nil, metadata: [String: String] = [:]) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.action = action
        self.sessionId = ProcessInfo.processInfo.globallyUniqueString
        self.businessIdeaId = businessIdeaId
        self.metadata = metadata
    }
}

// MARK: - User Insights
struct UserInsights: Codable {
    let preferredIndustries: [String]
    let commonKeywords: [String]
    let activityPatterns: [String: Int]
    let goalCompletionRate: Double
    let avgSessionLength: TimeInterval
    let lastActiveDate: Date
    let aiInteractionCount: Int
    let preferredReminderTimes: [Int] // Hours of day
    let businessFocusAreas: [String]
    
    static var empty: UserInsights {
        UserInsights(
            preferredIndustries: [],
            commonKeywords: [],
            activityPatterns: [:],
            goalCompletionRate: 0.0,
            avgSessionLength: 0,
            lastActiveDate: Date(),
            aiInteractionCount: 0,
            preferredReminderTimes: [],
            businessFocusAreas: []
        )
    }
}

// MARK: - Intelligent Context Manager
@MainActor
class IntelligentContextManager: ObservableObject {
    static let shared = IntelligentContextManager()
    
    @Published var contextEntries: [ContextEntry] = []
    @Published var userInsights: UserInsights = .empty
    @Published var isAnalyzing = false
    
    private let firestore = Firestore.firestore()
    private let maxContextEntries = 1000 // Keep last 1000 entries for performance
    private var currentUserId: String?
    
    private init() {
        startContextAnalysis()
    }
    
    // MARK: - Context Recording
    
    func recordAction(_ action: ContextAction, businessIdeaId: String? = nil, metadata: [String: String] = [:]) {
        let entry = ContextEntry(action: action, businessIdeaId: businessIdeaId, metadata: metadata)
        contextEntries.append(entry)
        
        // Keep only recent entries for performance
        if contextEntries.count > maxContextEntries {
            contextEntries = Array(contextEntries.suffix(maxContextEntries))
        }
        
        // Auto-save to Firebase
        Task {
            await saveContextEntry(entry)
            await updateUserInsights()
        }
    }
    
    // MARK: - AI Conversation Tracking
    
    func recordAIConversation(userMessage: String, aiResponse: String, businessIdeaId: String? = nil) {
        recordAction(
            .aiConversation(message: userMessage, response: aiResponse),
            businessIdeaId: businessIdeaId,
            metadata: [
                "message_length": "\(userMessage.count)",
                "response_length": "\(aiResponse.count)",
                "conversation_type": detectConversationType(userMessage)
            ]
        )
    }
    
    private func detectConversationType(_ message: String) -> String {
        let lowercased = message.lowercased()
        
        if lowercased.contains("business idea") || lowercased.contains("startup") {
            return "business_ideation"
        } else if lowercased.contains("timeline") || lowercased.contains("plan") || lowercased.contains("roadmap") {
            return "planning"
        } else if lowercased.contains("reminder") || lowercased.contains("schedule") {
            return "organization"
        } else if lowercased.contains("help") || lowercased.contains("how to") {
            return "guidance"
        } else {
            return "general"
        }
    }
    
    // MARK: - Note & Reminder Tracking
    
    func recordNoteCreated(content: String, category: String? = nil) {
        recordAction(
            .noteCreated(content: content, category: category ?? "general"),
            metadata: [
                "word_count": "\(content.split(separator: " ").count)",
                "has_business_keywords": "\(containsBusinessKeywords(content))"
            ]
        )
    }
    
    func recordReminderSet(title: String, date: Date, type: ReminderType) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        recordAction(
            .reminderSet(title: title, date: date, type: type),
            metadata: [
                "days_from_now": "\(calendar.dateComponents([.day], from: Date(), to: date).day ?? 0)",
                "hour_of_day": "\(hour)",
                "is_weekend": "\(calendar.isDateInWeekend(date))"
            ]
        )
    }
    
    // MARK: - Business Idea & Timeline Tracking
    
    func recordBusinessIdeaExplored(idea: String, industry: String? = nil) {
        recordAction(
            .businessIdeaExplored(idea: idea, industry: industry),
            metadata: [
                "idea_keywords": extractKeywords(from: idea).joined(separator: ","),
                "complexity_score": "\(calculateComplexityScore(idea))"
            ]
        )
    }
    
    func recordTimelineInteraction(action: TimelineAction, details: String? = nil, businessIdeaId: String? = nil) {
        recordAction(
            .timelineInteraction(action: action, details: details),
            businessIdeaId: businessIdeaId,
            metadata: [
                "interaction_details": details ?? "none"
            ]
        )
    }
    
    // MARK: - Context Analysis & Insights
    
    private func startContextAnalysis() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // Every 5 minutes
            Task { @MainActor in
                await self.updateUserInsights()
            }
        }
    }
    
    private func updateUserInsights() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let recentEntries = contextEntries.filter { 
            Calendar.current.dateComponents([.day], from: $0.timestamp, to: Date()).day ?? 0 <= 30 
        }
        
        // Analyze preferred industries
        let industries = recentEntries.compactMap { entry -> String? in
            if case .businessIdeaExplored(_, let industry) = entry.action {
                return industry
            }
            return nil
        }
        let preferredIndustries = Array(Set(industries)).sorted()
        
        // Extract common keywords
        let allContent = recentEntries.compactMap { entry -> String? in
            switch entry.action {
            case .aiConversation(let message, _):
                return message
            case .noteCreated(let content, _):
                return content
            case .businessIdeaExplored(let idea, _):
                return idea
            default:
                return nil
            }
        }.joined(separator: " ")
        
        let commonKeywords = Array(extractKeywords(from: allContent).prefix(10))
        
        // Activity patterns
        var activityPatterns: [String: Int] = [:]
        for entry in recentEntries {
            activityPatterns[entry.action.actionType, default: 0] += 1
        }
        
        // Calculate completion rate
        let goalsSet = recentEntries.filter { 
            if case .goalSet = $0.action { return true }
            return false 
        }.count
        
        let milestonesCompleted = recentEntries.filter { 
            if case .milestoneCompleted = $0.action { return true }
            return false 
        }.count
        
        let goalCompletionRate = goalsSet > 0 ? Double(milestonesCompleted) / Double(goalsSet) : 0.0
        
        // AI interaction count
        let aiInteractionCount = recentEntries.filter { 
            if case .aiConversation = $0.action { return true }
            return false 
        }.count
        
        // Preferred reminder times
        let reminderTimes = recentEntries.compactMap { entry -> Int? in
            if case .reminderSet(_, let date, _) = entry.action {
                return Calendar.current.component(.hour, from: date)
            }
            return nil
        }
        let preferredReminderTimes = Array(Set(reminderTimes)).sorted()
        
        // Business focus areas
        let businessFocusAreas = extractBusinessFocusAreas(from: recentEntries)
        
        userInsights = UserInsights(
            preferredIndustries: preferredIndustries,
            commonKeywords: Array(commonKeywords),
            activityPatterns: activityPatterns,
            goalCompletionRate: goalCompletionRate,
            avgSessionLength: calculateAverageSessionLength(recentEntries),
            lastActiveDate: Date(),
            aiInteractionCount: aiInteractionCount,
            preferredReminderTimes: preferredReminderTimes,
            businessFocusAreas: businessFocusAreas
        )
        
        // Save insights to Firebase
        await saveUserInsights()
    }
    
    // MARK: - Context for AI
    
    func buildEnhancedContext(for prompt: String) -> String {
        let recentEntries = contextEntries.suffix(50) // Last 50 actions
        
        var contextBuilder = """
        USER CONTEXT & BEHAVIORAL INSIGHTS:
        
        Recent Activity Patterns:
        """
        
        // Add activity summary
        let activitySummary = userInsights.activityPatterns.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        contextBuilder += "\n- \(activitySummary)"
        
        // Add business focus
        if !userInsights.businessFocusAreas.isEmpty {
            contextBuilder += "\n\nBusiness Focus Areas: \(userInsights.businessFocusAreas.joined(separator: ", "))"
        }
        
        // Add preferred industries
        if !userInsights.preferredIndustries.isEmpty {
            contextBuilder += "\n\nPreferred Industries: \(userInsights.preferredIndustries.joined(separator: ", "))"
        }
        
        // Add recent conversations context
        let recentAIConversations = recentEntries.compactMap { entry -> String? in
            if case .aiConversation(let message, let response) = entry.action {
                return "User: \(message)\nAI: \(response.prefix(100))..."
            }
            return nil
        }.suffix(3)
        
        if !recentAIConversations.isEmpty {
            contextBuilder += "\n\nRecent Conversations:\n"
            contextBuilder += recentAIConversations.joined(separator: "\n---\n")
        }
        
        // Add recent notes
        let recentNotes = recentEntries.compactMap { entry -> String? in
            if case .noteCreated(let content, let category) = entry.action {
                return "[\(category ?? "general")] \(content.prefix(50))..."
            }
            return nil
        }.suffix(3)
        
        if !recentNotes.isEmpty {
            contextBuilder += "\n\nRecent Notes:\n- "
            contextBuilder += recentNotes.joined(separator: "\n- ")
        }
        
        // Add behavioral insights
        contextBuilder += "\n\nUser Behavior Insights:"
        contextBuilder += "\n- Goal completion rate: \(Int(userInsights.goalCompletionRate * 100))%"
        contextBuilder += "\n- AI interactions in last 30 days: \(userInsights.aiInteractionCount)"
        
        if !userInsights.preferredReminderTimes.isEmpty {
            let timeStrings = userInsights.preferredReminderTimes.map { hour in
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
                return formatter.string(from: date)
            }
            contextBuilder += "\n- Preferred reminder times: \(timeStrings.joined(separator: ", "))"
        }
        
        contextBuilder += "\n\nCURRENT REQUEST: \(prompt)"
        
        return contextBuilder
    }
    
    // MARK: - Firebase Operations
    
    func setUserId(_ userId: String) {
        currentUserId = userId
        Task {
            await loadUserContext()
        }
    }
    
    private func saveContextEntry(_ entry: ContextEntry) async {
        guard let userId = currentUserId else { return }
        
        do {
            // Organized structure: users/{userId}/context/entries/{entryId}
            try await firestore
                .collection("users")
                .document(userId)
                .collection("context")
                .document("entries")
                .collection("items")
                .document(entry.id)
                .setData([
                    "id": entry.id,
                    "action": entry.action.actionType,
                    "sessionId": entry.sessionId,
                    "timestamp": Timestamp(date: entry.timestamp),
                    "businessIdeaId": entry.businessIdeaId ?? "",
                    "metadata": entry.metadata,
                    "createdAt": Timestamp(date: Date())
                ])
            
            // Also maintain a summary document for quick access
            await updateContextSummary()
            
            print("✅ Context entry saved: \(entry.action.actionType)")
        } catch {
            print("❌ Failed to save context entry: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func updateContextSummary() async {
        guard let userId = currentUserId else { return }
        
        do {
            let summaryData = [
                "totalEntries": contextEntries.count,
                "lastActivity": Timestamp(date: Date()),
                "recentActions": Array(contextEntries.suffix(5).map { $0.action.actionType }),
                "version": "1.0"
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("context")
                .document("summary")
                .setData(summaryData, merge: true)
            
        } catch {
            print("❌ Failed to update context summary: \(error)")
        }
    }
    
    private func saveUserInsights() async {
        guard let userId = currentUserId else { return }
        
        do {
            // Organized structure: users/{userId}/context/insights
            let insightsData = [
                "preferredIndustries": userInsights.preferredIndustries,
                "commonKeywords": userInsights.commonKeywords,
                "activityPatterns": userInsights.activityPatterns,
                "goalCompletionRate": userInsights.goalCompletionRate,
                "avgSessionLength": userInsights.avgSessionLength,
                "lastActiveDate": Timestamp(date: userInsights.lastActiveDate),
                "aiInteractionCount": userInsights.aiInteractionCount,
                "preferredReminderTimes": userInsights.preferredReminderTimes,
                "businessFocusAreas": userInsights.businessFocusAreas,
                "lastAnalyzed": Timestamp(date: Date()),
                "version": "1.0"
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("context")
                .document("insights")
                .setData(insightsData)
                
            print("✅ User insights saved to Firebase")
        } catch {
            print("❌ Failed to save user insights: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func loadUserContext() async {
        guard let userId = currentUserId else { return }
        
        do {
            // Load recent context entries
            let contextSnapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection("context")
                .order(by: "timestamp", descending: true)
                .limit(to: maxContextEntries)
                .getDocuments()
            
            let entries = contextSnapshot.documents.compactMap { document -> ContextEntry? in
                try? document.data(as: ContextEntry.self)
            }
            
            await MainActor.run {
                self.contextEntries = entries.reversed() // Restore chronological order
            }
            
            // Load user insights
            let insightsDoc = try await firestore
                .collection("users")
                .document(userId)
                .collection("insights")
                .document("current")
                .getDocument()
            
            if let insights = try? insightsDoc.data(as: UserInsights.self) {
                await MainActor.run {
                    self.userInsights = insights
                }
            }
            
        } catch {
            print("Failed to load user context: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func extractKeywords(from text: String) -> [String] {
        let businessKeywords = [
            "startup", "business", "revenue", "profit", "customer", "market", "product", 
            "service", "strategy", "growth", "innovation", "entrepreneur", "funding",
            "investor", "partnership", "scalable", "sustainable", "competitive", "niche",
            "target audience", "value proposition", "monetization", "marketing", "branding"
        ]
        
        let words = text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 3 }
        
        return businessKeywords.filter { keyword in
            words.contains { $0.contains(keyword) } || text.lowercased().contains(keyword)
        }
    }
    
    private func containsBusinessKeywords(_ text: String) -> Bool {
        return !extractKeywords(from: text).isEmpty
    }
    
    private func calculateComplexityScore(_ idea: String) -> Int {
        let factors = [
            idea.contains("tech") || idea.contains("technology") || idea.contains("AI") || idea.contains("software"),
            idea.contains("marketplace") || idea.contains("platform"),
            idea.contains("subscription") || idea.contains("SaaS"),
            idea.contains("hardware") || idea.contains("manufacturing"),
            idea.contains("international") || idea.contains("global"),
            idea.split(separator: " ").count > 10
        ]
        
        return factors.filter { $0 }.count
    }
    
    private func calculateAverageSessionLength(_ entries: [ContextEntry]) -> TimeInterval {
        // Group entries by date and calculate average time between first and last action per day
        let grouped = Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
        
        let sessionLengths = grouped.compactMap { (_, dayEntries) -> TimeInterval? in
            guard dayEntries.count > 1 else { return nil }
            let sorted = dayEntries.sorted { $0.timestamp < $1.timestamp }
            return sorted.last!.timestamp.timeIntervalSince(sorted.first!.timestamp)
        }
        
        return sessionLengths.isEmpty ? 0 : sessionLengths.reduce(0, +) / Double(sessionLengths.count)
    }
    
    private func extractBusinessFocusAreas(from entries: [ContextEntry]) -> [String] {
        let focusKeywords = [
            "e-commerce", "fintech", "healthtech", "edtech", "foodtech", "proptech",
            "logistics", "sustainability", "AI", "blockchain", "mobile app", "web app",
            "marketplace", "SaaS", "consulting", "retail", "manufacturing", "service"
        ]
        
        let allText = entries.compactMap { entry -> String? in
            switch entry.action {
            case .businessIdeaExplored(let idea, _):
                return idea
            case .aiConversation(let message, let response):
                return message + " " + response
            case .noteCreated(let content, _):
                return content
            default:
                return nil
            }
        }.joined(separator: " ").lowercased()
        
        return focusKeywords.filter { keyword in
            allText.contains(keyword)
        }
    }
}