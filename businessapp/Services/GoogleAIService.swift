import Foundation

// MARK: - AI Response Models

struct AIQuizQuestion: Codable {
    let question: String
    let options: [String]
    let category: String
}

struct AIBusinessAnalysis: Codable {
    let viabilityScore: Int
    let strengths: [String]
    let weaknesses: [String]
    let opportunities: [String]
    let threats: [String]
    let recommendations: [String]
}

class GoogleAIService {
    static let shared = GoogleAIService()
    
    private let apiKey = Config.googleAIKey
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    // MARK: - Generate Business Ideas
    
    func generateBusinessIdeas(
        skills: [String],
        personality: [String],
        interests: [String],
        completion: @escaping (Result<[BusinessIdea], Error>) -> Void
    ) {
        let prompt = buildPrompt(skills: skills, personality: personality, interests: interests)
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.success([]))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    
                    let ideas = self.parseBusinessIdeas(from: text)
                    completion(.success(ideas))
                } else {
                    completion(.success([]))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Get AI Suggestions
    
    func getAISuggestions(
        businessIdea: BusinessIdea,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        Provide practical, actionable advice for this business idea:
        
        Business: \(businessIdea.title)
        Description: \(businessIdea.description)
        Category: \(businessIdea.category)
        
        Format your response with clear sections:
        
        🎯 NEXT STEPS:
        - [Step 1]
        - [Step 2]
        - [Step 3]
        
        💡 KEY RECOMMENDATIONS:
        - [Recommendation 1]
        - [Recommendation 2]
        
        ⚠️ WATCH OUT FOR:
        - [Potential pitfall to avoid]
        
        Keep it concise, specific, and actionable.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.success("Unable to get suggestions at this time."))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.success("No suggestions available"))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Private Helper Methods
    
    // MARK: - Generate Quiz Questions with AI
    
    func generateQuizQuestions(
        step: Int,
        previousAnswers: [String: [String]],
        completion: @escaping (Result<[AIQuizQuestion], Error>) -> Void
    ) {
        let prompt = buildQuizPrompt(step: step, previousAnswers: previousAnswers)
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let text):
                let questions = self.parseQuizQuestions(from: text, step: step)
                completion(.success(questions))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Analyze Business Idea with AI
    
    func analyzeBusinessIdea(
        idea: BusinessIdea,
        userProfile: [String: Any],
        completion: @escaping (Result<AIBusinessAnalysis, Error>) -> Void
    ) {
        let prompt = buildAnalysisPrompt(idea: idea, userProfile: userProfile)
        makeAIRequest(prompt: prompt) { result in
            switch result {
                case .success(let text):
                let analysis = self.parseBusinessAnalysis(from: text, ideaTitle: idea.title)
                completion(.success(analysis))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Generate Daily Goals with AI
    
    func generateDailyGoals(
        businessIdea: BusinessIdea,
        currentProgress: Int,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let prompt = """
        Generate 3 specific, actionable daily goals for someone working on: \(businessIdea.title)
        Description: \(businessIdea.description)
        Current Progress: \(currentProgress)%
        
        Make each goal SMART (Specific, Measurable, Achievable, Relevant, Time-bound).
        
        Format your response as exactly 3 lines, each starting with a number:
        1. [Specific action to take today]
        2. [Specific action to take today]
        3. [Specific action to take today]
        
        Do not include any other text, headers, or explanations.
        """
        
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let text):
                let goals = self.parseGoalsList(from: text)
                completion(.success(goals))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Get Personalized Advice
    
    func getPersonalizedAdvice(
        context: String,
        userGoals: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        User Context: \(context)
        Current Goals: \(userGoals.joined(separator: ", "))
        
        Provide personalized, actionable advice in a clear, readable format:
        
        📊 CURRENT SITUATION:
        [Brief assessment]
        
        🚀 PRIORITY ACTIONS:
        1. [Most important next step]
        2. [Second priority]
        3. [Third priority]
        
        💪 ENCOURAGEMENT:
        [Specific, motivating message based on their context]
        
        Be specific, encouraging, and action-oriented. Keep it concise (2-3 short paragraphs total).
        """
        
        makeAIRequest(prompt: prompt, completion: completion)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildPrompt(skills: [String], personality: [String], interests: [String]) -> String {
        let skillsText = skills.joined(separator: ", ")
        let personalityText = personality.joined(separator: ", ")
        let interestsText = interests.joined(separator: ", ")
        
        return """
        You are an expert business advisor. Based on this profile, generate 5 highly personalized business ideas:
        
        Skills: \(skillsText)
        Personality: \(personalityText)
        Interests: \(interestsText)
        
        CRITICAL: For EACH of the 5 ideas, use this EXACT format with NO VARIATIONS:
        
        IDEA 1
        Title: [Concise business name]
        Description: [2-3 compelling sentences explaining the business concept and value proposition]
        Category: [MUST be ONE of: Technology, Service, Creative, Retail, Consulting]
        Difficulty: [MUST be: Easy, Medium, or Hard]
        Revenue: $[X]K - $[Y]K/year
        Launch: [X] weeks
        Skills: [skill1], [skill2], [skill3]
        Cost: $[X]K - $[Y]K
        Margin: [X]-[Y]%
        Demand: [MUST be: High, Medium, or Low]
        Competition: [MUST be: High, Medium, or Low]
        Note: [One personalized sentence explaining why this business fits their specific profile]
        
        IMPORTANT FORMATTING RULES:
        - Each field MUST be on its own line
        - Each field MUST start with the exact label followed by a colon
        - Revenue format: Use K for thousands (e.g., $50K - $150K/year)
        - Launch format: Use weeks or months (e.g., 6-8 weeks or 3-4 months)
        - Skills: Comma-separated list
        - Cost format: Use K for thousands (e.g., $5K - $15K)
        - Margin format: Range with dash (e.g., 40-60%)
        - DO NOT add extra spacing or blank lines between fields
        - REPEAT this exact structure for all 5 ideas
        
        Make ideas specific, innovative, and tailored to their unique combination of traits.
        """
    }
    
    private func buildQuizPrompt(step: Int, previousAnswers: [String: [String]]) -> String {
        switch step {
        case 1:
            return """
            Generate 8 diverse skill options for an entrepreneurship quiz.
            
            CRITICAL: Return ONLY the skill names, one per line.
            Do NOT include:
            - Numbers (1., 2., etc.)
            - Bullets (-, *, •)
            - Headers
            - Explanations
            
            Make them varied: technical, creative, business, interpersonal, etc.
            
            Example format:
            Data Analysis
            Graphic Design
            Public Speaking
            """
        case 2:
            let skills = previousAnswers["skills"] ?? []
            return """
            User selected skills: \(skills.joined(separator: ", "))
            Generate 6 personality traits relevant for entrepreneurship that complement these skills.
            
            CRITICAL: Return ONLY the trait names, one per line.
            Do NOT include numbers, bullets, headers, or explanations.
            
            Example format:
            Analytical
            Creative
            Risk-Taker
            """
        case 3:
            let skills = previousAnswers["skills"] ?? []
            let personality = previousAnswers["personality"] ?? []
            return """
            User profile - Skills: \(skills.joined(separator: ", ")), Personality: \(personality.joined(separator: ", "))
            Generate 8 business interest areas that align with this profile.
            
            CRITICAL: Return ONLY the interest areas, one per line.
            Do NOT include numbers, bullets, headers, or explanations.
            
            Example format:
            Technology
            E-commerce
            Consulting
            """
        default:
            return ""
        }
    }
    
    private func buildAnalysisPrompt(idea: BusinessIdea, userProfile: [String: Any]) -> String {
        return """
        Analyze this business idea thoroughly:
        Title: \(idea.title)
        Description: \(idea.description)
        Category: \(idea.category)
        
        Provide analysis in this EXACT format:
        
        VIABILITY: [score 0-100]
        
        STRENGTHS:
        - [strength 1]
        - [strength 2]
        - [strength 3]
        
        WEAKNESSES:
        - [weakness 1]
        - [weakness 2]
        
        OPPORTUNITIES:
        - [opportunity 1]
        - [opportunity 2]
        - [opportunity 3]
        
        THREATS:
        - [threat 1]
        - [threat 2]
        
        RECOMMENDATIONS:
        - [recommendation 1]
        - [recommendation 2]
        - [recommendation 3]
        """
    }
    
    private func makeAIRequest(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.9,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 2048
            ]
        ]
        
        var request = URLRequest(url: URL(string: "\(baseURL)?key=\(apiKey)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "GoogleAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "GoogleAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseBusinessIdeas(from text: String) -> [BusinessIdea] {
        var ideas: [BusinessIdea] = []
        let lines = text.components(separatedBy: "\n")
        var currentIdea: [String: String] = [:]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.starts(with: "IDEA") && !currentIdea.isEmpty {
                if let idea = createBusinessIdea(from: currentIdea) {
                    ideas.append(idea)
                }
                currentIdea = [:]
            } else if trimmed.contains(":") {
                let parts = trimmed.components(separatedBy: ":")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    currentIdea[key] = value
                }
            }
        }
        
        // Add last idea
        if !currentIdea.isEmpty, let idea = createBusinessIdea(from: currentIdea) {
            ideas.append(idea)
        }
        
        // If parsing failed, return fallback ideas
        if ideas.isEmpty {
            return generateFallbackIdeas()
        }
        
        return ideas
    }
    
    private func createBusinessIdea(from data: [String: String]) -> BusinessIdea? {
        guard let title = data["title"], !title.isEmpty else { return nil }
        
        let description = data["description"] ?? "Explore this business opportunity"
        let category = data["category"] ?? "General"
        let difficulty = data["difficulty"] ?? "Medium"
        let revenue = data["revenue"] ?? "$10,000 - $50,000/year"
        let launch = data["launch"] ?? "3-6 months"
        let cost = data["cost"] ?? "$1,000 - $5,000"
        let margin = data["margin"] ?? "30-50%"
        let demand = data["demand"] ?? "Medium"
        let competition = data["competition"] ?? "Medium"
        let note = data["note"] ?? "Great opportunity for growth"
        
        let skillsString = data["skills"] ?? ""
        let skills = skillsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        return BusinessIdea(
            id: UUID().uuidString,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedRevenue: revenue,
            timeToLaunch: launch,
            requiredSkills: skills,
            startupCost: cost,
            profitMargin: margin,
            marketDemand: demand,
            competition: competition,
            createdAt: Date(),
            userId: "",
            personalizedNotes: note
        )
    }
    
    private func extractViabilityScore(margin: String, demand: String, competition: String) -> Int {
        var score = 50
        
        // Adjust based on demand
        if demand.lowercased().contains("high") { score += 20 }
        else if demand.lowercased().contains("low") { score -= 10 }
        
        // Adjust based on competition
        if competition.lowercased().contains("low") { score += 15 }
        else if competition.lowercased().contains("high") { score -= 15 }
        
        // Adjust based on margin
        if margin.contains("-") {
            let numbers = margin.components(separatedBy: .decimalDigits.inverted).compactMap { Int($0) }
            if let avg = numbers.isEmpty ? nil : numbers.reduce(0, +) / numbers.count {
                if avg > 50 { score += 15 }
                else if avg < 30 { score -= 10 }
            }
        }
        
        return min(max(score, 0), 100)
    }
    
    private func parseQuizQuestions(from text: String, step: Int) -> [AIQuizQuestion] {
        let lines = text.components(separatedBy: "\n")
        let options = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.starts(with: "-") && !$0.starts(with: "*") }
            .map { $0.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression) }
        
        let category = step == 1 ? "skills" : step == 2 ? "personality" : "interests"
        let question = step == 1 ? "What are your key skills?" : step == 2 ? "Select your personality traits" : "What are your interests?"
        
        return [AIQuizQuestion(question: question, options: options, category: category)]
    }
    
    private func parseBusinessAnalysis(from text: String, ideaTitle: String) -> AIBusinessAnalysis {
        var viability = 70
        var strengths: [String] = []
        var weaknesses: [String] = []
        var opportunities: [String] = []
        var threats: [String] = []
        var recommendations: [String] = []
        
        let lines = text.components(separatedBy: "\n")
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.uppercased().contains("VIABILITY") {
                currentSection = "viability"
                if let score = Int(trimmed.components(separatedBy: .decimalDigits.inverted).joined()) {
                    viability = score
                }
            } else if trimmed.uppercased().contains("STRENGTHS") {
                currentSection = "strengths"
            } else if trimmed.uppercased().contains("WEAKNESSES") {
                currentSection = "weaknesses"
            } else if trimmed.uppercased().contains("OPPORTUNITIES") {
                currentSection = "opportunities"
            } else if trimmed.uppercased().contains("THREATS") {
                currentSection = "threats"
            } else if trimmed.uppercased().contains("RECOMMENDATIONS") {
                currentSection = "recommendations"
            } else if trimmed.starts(with: "-") || trimmed.starts(with: "•") {
                let item = trimmed.replacingOccurrences(of: "^[-•]\\s*", with: "", options: .regularExpression)
                switch currentSection {
                case "strengths": strengths.append(item)
                case "weaknesses": weaknesses.append(item)
                case "opportunities": opportunities.append(item)
                case "threats": threats.append(item)
                case "recommendations": recommendations.append(item)
                default: break
                }
            }
        }
        
        return AIBusinessAnalysis(
            viabilityScore: viability,
            strengths: strengths.isEmpty ? ["Strong market fit", "Innovative approach"] : strengths,
            weaknesses: weaknesses.isEmpty ? ["Needs market validation"] : weaknesses,
            opportunities: opportunities.isEmpty ? ["Growing market demand", "Digital transformation"] : opportunities,
            threats: threats.isEmpty ? ["Competition"] : threats,
            recommendations: recommendations.isEmpty ? ["Start with MVP", "Validate with customers", "Build audience"] : recommendations
        )
    }
    
    private func parseGoalsList(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        return lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.replacingOccurrences(of: "^[0-9]+\\.\\s*", with: "", options: .regularExpression) }
            .prefix(3)
            .map { String($0) }
    }
    
    private func generateFallbackIdeas() -> [BusinessIdea] {
        return [
            BusinessIdea(
                id: UUID().uuidString,
                title: "AI-Powered Consulting Services",
                description: "Leverage AI and your expertise to provide consulting services to businesses looking to modernize.",
                category: "Technology",
                difficulty: "Medium",
                estimatedRevenue: "$75,000 - $150,000/year",
                timeToLaunch: "2-3 months",
                requiredSkills: ["Business Analysis", "AI/ML", "Communication"],
                startupCost: "$2,000 - $5,000",
                profitMargin: "60-80%",
                marketDemand: "High",
                competition: "Medium",
                createdAt: Date(),
                userId: "",
                personalizedNotes: "Perfect for leveraging modern technology trends"
            ),
            BusinessIdea(
                id: UUID().uuidString,
                title: "Digital Content Creation Studio",
                description: "Create and monetize digital content across multiple platforms, from courses to social media.",
                category: "Creative",
                difficulty: "Easy",
                estimatedRevenue: "$30,000 - $100,000/year",
                timeToLaunch: "1-2 months",
                requiredSkills: ["Content Creation", "Marketing", "Video Editing"],
                startupCost: "$500 - $2,000",
                profitMargin: "70-90%",
                marketDemand: "High",
                competition: "High",
                createdAt: Date(),
                userId: "",
                personalizedNotes: "Low barrier to entry with high growth potential"
            ),
            BusinessIdea(
                id: UUID().uuidString,
                title: "Specialized E-Learning Platform",
                description: "Build a niche online learning platform focused on high-demand skills in your area of expertise.",
                category: "Education",
                difficulty: "Medium",
                estimatedRevenue: "$50,000 - $200,000/year",
                timeToLaunch: "3-4 months",
                requiredSkills: ["Teaching", "Course Design", "Marketing"],
                startupCost: "$3,000 - $10,000",
                profitMargin: "50-70%",
                marketDemand: "High",
                competition: "Medium",
                createdAt: Date(),
                userId: "",
                personalizedNotes: "Scalable model with recurring revenue potential"
            )
        ]
    }
}
