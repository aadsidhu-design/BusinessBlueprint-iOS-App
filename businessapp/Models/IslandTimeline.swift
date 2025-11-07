import Foundation
import SwiftUI

// MARK: - Island Model
struct Island: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var goalIds: [String] // References to DailyGoal IDs
    var isCompleted: Bool
    var position: CGPoint // Position in the island map
    var type: IslandType
    var unlockedAt: Date?
    var completedAt: Date?
    var order: Int?
    var duration: String?
    var keyTasks: [String]?
    var successMetrics: [String]?
    var emoji: String?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        goalIds: [String] = [],
        isCompleted: Bool = false,
        position: CGPoint,
        type: IslandType = .regular,
        unlockedAt: Date? = Date(),
        completedAt: Date? = nil,
        order: Int? = nil,
        duration: String? = nil,
        keyTasks: [String]? = nil,
        successMetrics: [String]? = nil,
        emoji: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.goalIds = goalIds
        self.isCompleted = isCompleted
        self.position = position
        self.type = type
        self.unlockedAt = unlockedAt
        self.completedAt = completedAt
        self.order = order
        self.duration = duration
        self.keyTasks = keyTasks
        self.successMetrics = successMetrics
        self.emoji = emoji
    }
}

// MARK: - Island Types
enum IslandType: String, Codable {
    case start = "start"
    case regular = "regular"
    case milestone = "milestone"
    case treasure = "treasure" // Final goal
    
    var icon: String {
        switch self {
        case .start: return "🏝️"
        case .regular: return "🏔️"
        case .milestone: return "🏰"
        case .treasure: return "💎"
        }
    }
    
    var color: Color {
        switch self {
        case .start: return .green
        case .regular: return .blue
        case .milestone: return .purple
        case .treasure: return .yellow
        }
    }
}

// MARK: - Progress Note
struct ProgressNote: Identifiable, Codable {
    let id: String
    var content: String
    var islandId: String?
    var goalId: String?
    var createdAt: Date
    var tags: [String]
    
    init(
        id: String = UUID().uuidString,
        content: String,
        islandId: String? = nil,
        goalId: String? = nil,
        createdAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = id
        self.content = content
        self.islandId = islandId
        self.goalId = goalId
        self.createdAt = createdAt
        self.tags = tags
    }
}

// MARK: - Reminder
struct AppReminder: Identifiable, Codable {
    let id: String
    var title: String
    var message: String
    var scheduledDate: Date
    var isCompleted: Bool
    var islandId: String?
    var goalId: String?
    var notifyViaCalendar: Bool
    
    init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        scheduledDate: Date,
        isCompleted: Bool = false,
        islandId: String? = nil,
        goalId: String? = nil,
        notifyViaCalendar: Bool = false
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.scheduledDate = scheduledDate
        self.isCompleted = isCompleted
        self.islandId = islandId
        self.goalId = goalId
        self.notifyViaCalendar = notifyViaCalendar
    }
}

// MARK: - Journey Progress
struct JourneyProgress: Codable {
    var currentIslandId: String?
    var completedIslandIds: [String]
    var totalDistance: Double
    var lastUpdated: Date
    
    init(
        currentIslandId: String? = nil,
        completedIslandIds: [String] = [],
        totalDistance: Double = 0,
        lastUpdated: Date = Date()
    ) {
        self.currentIslandId = currentIslandId
        self.completedIslandIds = completedIslandIds
        self.totalDistance = totalDistance
        self.lastUpdated = lastUpdated
    }
}

// MARK: - AI Generated Timeline Island
struct TimelineIsland: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var duration: String
    var keyTasks: [String]
    var successMetrics: [String]
    var emoji: String
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        duration: String,
        keyTasks: [String],
        successMetrics: [String],
        emoji: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.keyTasks = keyTasks
        self.successMetrics = successMetrics
        self.emoji = emoji
    }
}
