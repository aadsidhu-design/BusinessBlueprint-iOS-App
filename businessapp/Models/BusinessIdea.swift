import Foundation

struct BusinessIdea: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    var industry: String { return category } // Alias for backward compatibility
    let difficulty: String // Easy, Medium, Hard
    let estimatedRevenue: String
    let timeToLaunch: String
    let requiredSkills: [String]
    let startupCost: String
    let profitMargin: String
    let marketDemand: String // High, Medium, Low
    let competition: String // High, Medium, Low
    let createdAt: Date
    let userId: String
    let personalizedNotes: String
    var saved: Bool = false
    var progress: Int = 0 // 0-100
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, difficulty
        case estimatedRevenue = "estimated_revenue"
        case timeToLaunch = "time_to_launch"
        case requiredSkills = "required_skills"
        case startupCost = "startup_cost"
        case profitMargin = "profit_margin"
        case marketDemand = "market_demand"
        case competition
        case createdAt = "created_at"
        case userId = "user_id"
        case personalizedNotes = "personalized_notes"
        case saved
        case progress
    }
}

struct DailyGoal: Identifiable, Codable {
    let id: String
    let businessIdeaId: String
    let title: String
    let description: String
    let dueDate: Date
    var completed: Bool
    let priority: String // High, Medium, Low
    let createdAt: Date
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, priority
        case businessIdeaId = "business_idea_id"
        case dueDate = "due_date"
        case completed
        case createdAt = "created_at"
        case userId = "user_id"
    }
}

struct Milestone: Identifiable, Codable {
    let id: String
    let businessIdeaId: String
    let title: String
    let description: String
    let dueDate: Date
    var completed: Bool
    let order: Int
    let createdAt: Date
    let userId: String
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, order
        case businessIdeaId = "business_idea_id"
        case dueDate = "due_date"
        case completed
        case createdAt = "created_at"
        case userId = "user_id"
    }
}

struct UserProfile: Identifiable, Codable {
    let id: String
    let email: String
    var firstName: String
    var lastName: String
    var skills: [String]
    var personality: [String]
    var interests: [String]
    var createdAt: Date
    var subscriptionTier: String // free, pro, premium
    
    enum CodingKeys: String, CodingKey {
        case id, email, skills, personality, interests
        case firstName = "first_name"
        case lastName = "last_name"
        case createdAt = "created_at"
        case subscriptionTier = "subscription_tier"
    }
}

extension BusinessIdea {
    func withUserId(_ userId: String) -> BusinessIdea {
        BusinessIdea(
            id: id,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedRevenue: estimatedRevenue,
            timeToLaunch: timeToLaunch,
            requiredSkills: requiredSkills,
            startupCost: startupCost,
            profitMargin: profitMargin,
            marketDemand: marketDemand,
            competition: competition,
            createdAt: createdAt,
            userId: userId,
            personalizedNotes: personalizedNotes,
            saved: saved,
            progress: progress
        )
    }
    
    func updating(saved: Bool? = nil, progress: Int? = nil) -> BusinessIdea {
        BusinessIdea(
            id: id,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedRevenue: estimatedRevenue,
            timeToLaunch: timeToLaunch,
            requiredSkills: requiredSkills,
            startupCost: startupCost,
            profitMargin: profitMargin,
            marketDemand: marketDemand,
            competition: competition,
            createdAt: createdAt,
            userId: userId,
            personalizedNotes: personalizedNotes,
            saved: saved ?? self.saved,
            progress: progress ?? self.progress
        )
    }
}
