import Foundation

struct Question: Identifiable, Codable {
    let id: String
    let text: String
    let options: [String]
    var selectedOption: String?
    var allowsMultiple: Bool
    
    init(id: String, text: String, options: [String], allowsMultiple: Bool = false, selectedOption: String? = nil) {
        self.id = id
        self.text = text
        self.options = options
        self.allowsMultiple = allowsMultiple
        self.selectedOption = selectedOption
    }
}

struct StaticQuestions {
    static let questions: [Question] = [
        Question(
            id: "q1_kind",
            text: "What kind of business gets you excited?",
            options: ["Tech & apps", "E-commerce or online sales", "Health & wellness", "Finance or investing", "Education or coaching", "Creative arts & content", "Something else (tell us!)"]
        ),
        Question(
            id: "q2_why",
            text: "Why do you want to start this business?",
            options: ["To make money and become financially independent", "To turn it into a full-time career", "To create a side hustle or extra income", "To make a positive impact in the world", "To learn and gain experience"]
        ),
        Question(
            id: "q3_superpowers",
            text: "What are your superpowers? (Choose all that apply)",
            options: ["Leadership & strategy", "Marketing & sales", "Tech & coding", "Writing & content creation", "Design & visuals", "Networking & connecting with people", "Other (describe)"],
            allowsMultiple: true
        ),
        Question(
            id: "q4_time",
            text: "How much time can you realistically dedicate each week?",
            options: ["Just a few hours (<5)", "Some time (5–10 hours)", "A decent chunk (10–20 hours)", "I’m all in (20+ hours)"]
        ),
        Question(
            id: "q5_resources",
            text: "What resources do you already have to start your business?",
            options: ["Savings or funding", "Connections & network", "Equipment or tools", "Existing audience or followers", "Knowledge or skills", "Other (describe)"],
            allowsMultiple: true
        ),
        Question(
            id: "q6_type",
            text: "What type of business feels right for you?",
            options: ["Selling products", "Offering services", "Subscription or recurring revenue", "Affiliate or partner-based", "App/software-based", "Something else" ]
        ),
        Question(
            id: "q7_risk",
            text: "How do you feel about risk?",
            options: ["I thrive on it!", "I’m okay with some risk", "Neutral", "I prefer to be cautious", "I avoid risk whenever possible"]
        ),
        Question(
            id: "q8_drives",
            text: "What drives you most in a business?",
            options: ["Creativity & innovation", "Profit & growth", "Helping others", "Recognition & influence", "Independence & freedom"]
        ),
        Question(
            id: "q9_workstyle",
            text: "How do you like to work?",
            options: ["Solo, I’m self-sufficient", "With a small, tight-knit team", "With a larger team", "Flexible—depends on the project"]
        ),
        Question(
            id: "q10_challenge",
            text: "What’s your biggest challenge right now?",
            options: ["Time", "Money/funding", "Knowledge or skills", "Confidence", "Connections/network", "Other (tell us!)"]
        )
    ]
}
