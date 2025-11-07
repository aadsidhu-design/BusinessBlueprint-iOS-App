import Foundation
import FirebaseFirestore

// MARK: - User Context System

struct UserContext: Codable, Identifiable {
    let id: String
    let userId: String
    var createdAt: Date
    var lastUpdated: Date
    
    // Core Profile
    var profile: UserProfile
    var preferences: UserPreferences
    
    // Behavioral Data
    var behaviorPatterns: BehaviorPatterns
    var interactionHistory: [InteractionEvent]
    var goalPatterns: GoalPatterns
    var decisionPatterns: DecisionPatterns
    
    // Business Journey
    var businessJourney: BusinessJourney
    var skillsEvolution: SkillsEvolution
    var personalityInsights: PersonalityInsights
    
    // AI Context
    var aiContext: AIContext
    var communicationStyle: CommunicationStyle
    
    init(userId: String, profile: UserProfile) {
        self.id = UUID().uuidString
        self.userId = userId
        self.profile = profile
        self.createdAt = Date()
        self.lastUpdated = Date()
        
        // Initialize with defaults
        self.preferences = UserPreferences()
        self.behaviorPatterns = BehaviorPatterns()
        self.interactionHistory = []
        self.goalPatterns = GoalPatterns()
        self.decisionPatterns = DecisionPatterns()
        self.businessJourney = BusinessJourney()
        self.skillsEvolution = SkillsEvolution(initialSkills: profile.skills)
        self.personalityInsights = PersonalityInsights(baseTraits: profile.personality)
        self.aiContext = AIContext()
        self.communicationStyle = CommunicationStyle()
    }
}

// MARK: - Behavior Patterns

struct BehaviorPatterns: Codable {
    var sessionDuration: TimeInterval = 0
    var dailyActivityPattern: [Int: Double] = [:] // Hour -> Activity Score
    var weeklyActivityPattern: [Int: Double] = [:] // Day -> Activity Score
    var featureUsage: [String: Int] = [:]
    var navigationPatterns: [String] = []
    var engagementLevel: EngagementLevel = .medium
    var preferredInteractionTimes: [DateComponents] = []
    
    enum EngagementLevel: String, Codable, CaseIterable {
        case low, medium, high, veryHigh
        
        var description: String {
            switch self {
            case .low: return "Casual explorer"
            case .medium: return "Regular user" 
            case .high: return "Engaged entrepreneur"
            case .veryHigh: return "Power user"
            }
        }
    }
}

// MARK: - Interaction Events

struct InteractionEvent: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let eventType: EventType
    let context: [String: String]
    let outcome: EventOutcome?
    
    enum EventType: String, Codable, CaseIterable {
        case goalCreated, goalCompleted, goalAbandoned, goalReopened
        case ideaViewed, ideaFavorited, ideaSelected
        case aiQuestionAsked, aiSuggestionAccepted, aiSuggestionDismissed
        case aiInteractionStarted, aiResponseReceived, aiInteractionFailed
        case milestoneCompleted, reminderSet, reminderCompleted
        case quizCompleted, quizStarted
        case businessIdeasGenerated, businessIdeaSelected
        case noteCreated, noteDeleted, noteAdded
        case settingsChanged, featureDiscovered
        case sessionStarted, sessionEnded
        case errorEncountered, helpSought
        case viewOpened, navigationOccurred
    }
    
    enum EventOutcome: String, Codable {
        case successful, failed, abandoned, dismissed
    }
    
    init(type: EventType, context: [String: String] = [:], outcome: EventOutcome? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.eventType = type
        self.context = context
        self.outcome = outcome
    }
}

// MARK: - Goal Patterns

struct GoalPatterns: Codable {
    var goalCreationFrequency: Double = 0 // Goals per week
    var goalCompletionRate: Double = 0 // Percentage completed
    var averageGoalDuration: TimeInterval = 0
    var preferredGoalTypes: [String] = []
    var goalComplexityPreference: ComplexityLevel = .medium
    var mostProductiveTimeframes: [String] = []
    var goalAbandonmentReasons: [String: Int] = [:]
    
    enum ComplexityLevel: String, Codable, CaseIterable {
        case simple, medium, complex, advanced
    }
}

// MARK: - Decision Patterns

struct DecisionPatterns: Codable {
    var decisionSpeed: DecisionSpeed = .moderate
    var riskTolerance: RiskTolerance = .moderate
    var preferredInformationDepth: InformationDepth = .moderate
    var decisionConfidence: Double = 0.5
    var changeAdaptability: Double = 0.5
    var collaborationPreference: Double = 0.5 // 0 = solo, 1 = team-oriented
    
    enum DecisionSpeed: String, Codable, CaseIterable {
        case quick, moderate, deliberate, thorough
    }
    
    enum RiskTolerance: String, Codable, CaseIterable {
        case conservative, moderate, adventurous, aggressive
    }
    
    enum InformationDepth: String, Codable, CaseIterable {
        case summary, moderate, detailed, comprehensive
    }
}

// MARK: - Business Journey

struct BusinessJourney: Codable {
    var currentStage: EntrepreneurshipStage = .exploring
    var journeyStartDate: Date = Date()
    var milestonesAchieved: [String] = []
    var challengesFaced: [BusinessChallenge] = []
    var skillGaps: [String] = []
    var strengthAreas: [String] = []
    var industryExperience: [String: ExperienceLevel] = [:]
    var mentorshipNeeds: [String] = []
    
    enum EntrepreneurshipStage: String, Codable, CaseIterable {
        case exploring = "Exploring Ideas"
        case validating = "Validating Concept"
        case planning = "Business Planning"
        case launching = "Launching"
        case growing = "Growing Business"
        case scaling = "Scaling Operations"
        case established = "Established Business"
    }
    
    enum ExperienceLevel: String, Codable, CaseIterable {
        case none, basic, intermediate, advanced, expert
    }
}

struct BusinessChallenge: Codable, Identifiable {
    let id: String
    let challenge: String
    let category: String
    let severity: ChallengeSeverity
    let dateEncountered: Date
    let resolution: String?
    let dateResolved: Date?
    
    enum ChallengeSeverity: String, Codable, CaseIterable {
        case minor, moderate, significant, critical
    }
    
    init(challenge: String, category: String, severity: ChallengeSeverity) {
        self.id = UUID().uuidString
        self.challenge = challenge
        self.category = category
        self.severity = severity
        self.dateEncountered = Date()
        self.resolution = nil
        self.dateResolved = nil
    }
}

// MARK: - Skills Evolution

struct SkillsEvolution: Codable {
    var initialSkills: [String]
    var currentSkills: [String]
    var skillDevelopmentPath: [SkillDevelopment] = []
    var recommendedSkills: [String] = []
    var skillConfidenceLevels: [String: Double] = [:]
    
    init(initialSkills: [String]) {
        self.initialSkills = initialSkills
        self.currentSkills = initialSkills
    }
}

struct SkillDevelopment: Codable, Identifiable {
    let id: String
    let skillName: String
    let startDate: Date
    let progressLevel: Double // 0.0 to 1.0
    let learningMethod: String
    let milestonesCompleted: [String]
    
    init(skillName: String, learningMethod: String) {
        self.id = UUID().uuidString
        self.skillName = skillName
        self.startDate = Date()
        self.progressLevel = 0.0
        self.learningMethod = learningMethod
        self.milestonesCompleted = []
    }
}

// MARK: - Personality Insights

struct PersonalityInsights: Codable {
    var baseTraits: [String]
    var evolvedTraits: [PersonalityTrait] = []
    var workingStyle: WorkingStyle = .balanced
    var motivationFactors: [String] = []
    var stressIndicators: [String] = []
    var communicationPreferences: [String] = []
    
    init(baseTraits: [String]) {
        self.baseTraits = baseTraits
    }
    
    enum WorkingStyle: String, Codable, CaseIterable {
        case methodical, creative, collaborative, independent, balanced
    }
}

struct PersonalityTrait: Codable, Identifiable {
    let id: String
    let traitName: String
    let strength: Double // 0.0 to 1.0
    let manifestations: [String]
    let businessImpact: String
    
    init(traitName: String, strength: Double, manifestations: [String], businessImpact: String) {
        self.id = UUID().uuidString
        self.traitName = traitName
        self.strength = strength
        self.manifestations = manifestations
        self.businessImpact = businessImpact
    }
}

// MARK: - AI Context

struct AIContext: Codable {
    var conversationHistory: [AIConversation] = []
    var preferredResponseStyle: ResponseStyle = .balanced
    var topicExpertise: [String: Double] = [:] // Topic -> Expertise Level
    var questionPatterns: [String] = []
    var feedbackHistory: [AIFeedback] = []
    var personalizedPrompts: [String] = []
    
    enum ResponseStyle: String, Codable, CaseIterable {
        case concise, detailed, conversational, technical, motivational, balanced
    }
}

struct AIConversation: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let userQuery: String
    let aiResponse: String
    let context: String
    let userFeedback: FeedbackType?
    let topics: [String]
    
    enum FeedbackType: String, Codable {
        case helpful, notHelpful, tooLong, tooShort, irrelevant, perfect
    }
    
    init(userQuery: String, aiResponse: String, context: String, topics: [String] = []) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.userQuery = userQuery
        self.aiResponse = aiResponse
        self.context = context
        self.userFeedback = nil
        self.topics = topics
    }
}

struct AIFeedback: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let conversationId: String
    let feedbackType: AIConversation.FeedbackType
    let additionalNotes: String?
    
    init(conversationId: String, feedbackType: AIConversation.FeedbackType, additionalNotes: String? = nil) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.conversationId = conversationId
        self.feedbackType = feedbackType
        self.additionalNotes = additionalNotes
    }
}

// MARK: - Communication Style

struct CommunicationStyle: Codable {
    var preferredTone: CommunicationTone = .professional
    var formalityLevel: FormalityLevel = .moderate
    var detailPreference: DetailPreference = .balanced
    var encouragementStyle: EncouragementStyle = .supportive
    var feedbackReceptiveness: Double = 0.5
    
    enum CommunicationTone: String, Codable, CaseIterable {
        case professional, casual, friendly, motivational, analytical
    }
    
    enum FormalityLevel: String, Codable, CaseIterable {
        case formal, moderate, casual, informal
    }
    
    enum DetailPreference: String, Codable, CaseIterable {
        case brief, balanced, detailed, comprehensive
    }
    
    enum EncouragementStyle: String, Codable, CaseIterable {
        case gentle, supportive, challenging, direct, inspirational
    }
}

// MARK: - User Preferences

struct UserPreferences: Codable {
    var notificationSettings: NotificationSettings = NotificationSettings()
    var privacySettings: PrivacySettings = PrivacySettings()
    var displaySettings: DisplaySettings = DisplaySettings()
    var aiSettings: AISettings = AISettings()
    
    struct NotificationSettings: Codable {
        var dailyReminders: Bool = true
        var goalDeadlines: Bool = true
        var milestoneAlerts: Bool = true
        var aiSuggestions: Bool = true
        var weeklyProgress: Bool = true
        var preferredTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    }
    
    struct PrivacySettings: Codable {
        var dataCollection: Bool = true
        var personalization: Bool = true
        var analytics: Bool = true
        var aiTraining: Bool = true
    }
    
    struct DisplaySettings: Codable {
        var theme: String = "auto"
        var language: String = "en"
        var currency: String = "USD"
        var dateFormat: String = "MM/dd/yyyy"
    }
    
    struct AISettings: Codable {
        var adaptiveLearning: Bool = true
        var personalizedSuggestions: Bool = true
        var contextAwareness: Bool = true
        var proactiveInsights: Bool = true
    }
}