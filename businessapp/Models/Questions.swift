import Foundation

struct Question: Identifiable, Codable {
    let id: String
    let text: String
    let options: [String]
    var selectedOption: String?
    
    init(id: String, text: String, options: [String], selectedOption: String? = nil) {
        self.id = id
        self.text = text
        self.options = options
        self.selectedOption = selectedOption
    }
}

struct StaticQuestions {
    static let questions: [Question] = [
        Question(
            id: "experience",
            text: "What's your current business experience level?",
            options: ["Beginner - Just starting out", "Intermediate - Some experience", "Advanced - Seasoned entrepreneur"]
        ),
        Question(
            id: "industry",
            text: "Which industry interests you most?",
            options: ["Technology", "Healthcare", "Retail", "Food & Beverage", "Professional Services", "Other"]
        ),
        Question(
            id: "timeline",
            text: "When do you want to launch your business?",
            options: ["Within 3 months", "3-6 months", "6-12 months", "Just exploring"]
        ),
        Question(
            id: "budget",
            text: "What's your estimated startup budget?",
            options: ["Under $5,000", "$5,000 - $25,000", "$25,000 - $100,000", "Over $100,000"]
        ),
        Question(
            id: "goal",
            text: "What's your primary business goal?",
            options: ["Generate income", "Build a brand", "Solve a problem", "Create impact", "Multiple goals"]
        )
    ]
}
