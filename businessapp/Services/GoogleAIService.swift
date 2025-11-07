import Foundation

enum GoogleAIError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidResponse
    case emptyResponse
    case httpError(status: Int, message: String)
    case serializationFailure
    case rateLimited
    case quotaExceeded  
    case contentBlocked(String)
    case serviceUnavailable
    case authenticationFailed
    case requestTooLarge
    case networkTimeout
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not configured. Please check your settings."
        case .invalidResponse:
            return "Received unexpected response from AI service"
        case .emptyResponse:
            return "AI service returned empty response"
        case .httpError(let status, let message):
            return "AI service error (\(status)): \(message)"
        case .serializationFailure:
            return "Failed to prepare request data"
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        case .quotaExceeded:
            return "API quota exceeded. Please try again later."
        case .contentBlocked(let reason):
            return "Content blocked: \(reason)"
        case .serviceUnavailable:
            return "AI service is temporarily unavailable"
        case .authenticationFailed:
            return "Authentication failed. Please check API credentials."
        case .requestTooLarge:
            return "Request too large. Please try with shorter content."
        case .networkTimeout:
            return "Request timed out. Please check your connection."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .missingAPIKey:
            return "Configure your Google AI API key in the app settings."
        case .rateLimited:
            return "Wait a few moments before making another request."
        case .quotaExceeded:
            return "Your API quota has been exceeded. Check your Google AI console."
        case .serviceUnavailable, .networkTimeout:
            return "The service should be available again shortly."
        case .authenticationFailed:
            return "Verify your API key is correct and has proper permissions."
        case .requestTooLarge:
            return "Try breaking your request into smaller parts."
        default:
            return "Try again in a few moments."
        }
    }
    
    static func == (lhs: GoogleAIError, rhs: GoogleAIError) -> Bool {
        switch (lhs, rhs) {
        case (.missingAPIKey, .missingAPIKey),
             (.invalidResponse, .invalidResponse),
             (.emptyResponse, .emptyResponse),
             (.serializationFailure, .serializationFailure),
             (.rateLimited, .rateLimited),
             (.quotaExceeded, .quotaExceeded),
             (.serviceUnavailable, .serviceUnavailable),
             (.authenticationFailed, .authenticationFailed),
             (.requestTooLarge, .requestTooLarge),
             (.networkTimeout, .networkTimeout):
            return true
        case (.httpError(let status1, let msg1), .httpError(let status2, let msg2)):
            return status1 == status2 && msg1 == msg2
        case (.contentBlocked(let msg1), .contentBlocked(let msg2)),
             (.unknownError(let msg1), .unknownError(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

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
    private var baseURLString: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(Config.googleAIModel):generateContent"
    }
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        return URLSession(configuration: configuration)
    }()

    private func endpointURL() -> URL? {
        guard !apiKey.isEmpty else { return nil }
        return URL(string: "\(baseURLString)?key=\(apiKey)")
    }
    
    private func sendRequest(body: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = endpointURL() else {
            DispatchQueue.main.async {
                completion(.failure(GoogleAIError.missingAPIKey))
            }
            return
        }
        
        do {
            let payload = try JSONSerialization.data(withJSONObject: body)
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = payload
            request.timeoutInterval = 30 // 30 second timeout
            
            urlSession.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    // Handle network errors
                    if let error = error {
                        let nsError = error as NSError
                        if nsError.code == NSURLErrorTimedOut {
                            completion(.failure(GoogleAIError.networkTimeout))
                        } else if nsError.code == NSURLErrorNotConnectedToInternet {
                            completion(.failure(GoogleAIError.unknownError("No internet connection")))
                        } else {
                            completion(.failure(GoogleAIError.unknownError(error.localizedDescription)))
                        }
                        return
                    }
                    
                    guard let http = response as? HTTPURLResponse else {
                        completion(.failure(GoogleAIError.invalidResponse))
                        return
                    }
                    
                    // Handle specific HTTP status codes
                    switch http.statusCode {
                    case 200...299:
                        guard let data = data, !data.isEmpty else {
                            completion(.failure(GoogleAIError.emptyResponse))
                            return
                        }
                        completion(.success(data))
                        
                    case 400:
                        let message = self.parseAPIErrorMessage(from: data) ?? "Bad request"
                        if message.lowercased().contains("blocked") {
                            completion(.failure(GoogleAIError.contentBlocked(message)))
                        } else if message.lowercased().contains("too large") {
                            completion(.failure(GoogleAIError.requestTooLarge))
                        } else {
                            completion(.failure(GoogleAIError.httpError(status: http.statusCode, message: message)))
                        }
                        
                    case 401, 403:
                        completion(.failure(GoogleAIError.authenticationFailed))
                        
                    case 429:
                        completion(.failure(GoogleAIError.rateLimited))
                        
                    case 500...599:
                        completion(.failure(GoogleAIError.serviceUnavailable))
                        
                    default:
                        let message = self.parseAPIErrorMessage(from: data) ?? HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
                        completion(.failure(GoogleAIError.httpError(status: http.statusCode, message: message)))
                    }
                }
            }.resume()
            
        } catch {
            DispatchQueue.main.async {
                completion(.failure(GoogleAIError.serializationFailure))
            }
        }
    }

    private func parseAPIErrorMessage(from data: Data?) -> String? {
        guard let data = data else { return nil }
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let error = json["error"] as? [String: Any] {
                if let message = error["message"] as? String { return message }
                if let status = error["status"] as? String { return status }
            }
            if let feedback = json["promptFeedback"] as? [String: Any],
               let blockReason = feedback["blockReason"] as? String {
                return "Prompt blocked: \(blockReason.capitalized)"
            }
        }
        return nil
    }
    
    // MARK: - Generate Business Ideas
    
    func generateBusinessIdeas(
        skills: [String],
        personality: [String],
        interests: [String],
        completion: @escaping (Result<[BusinessIdea], Error>) -> Void
    ) {
        let basePrompt = buildPrompt(skills: skills, personality: personality, interests: interests)
        let contextualPrompt = UserContextManager.shared.enhanceAIPrompt(
            basePrompt: basePrompt,
            context: "business_idea_generation"
        )
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contextualPrompt]
                    ]
                ]
            ]
        ]
        
        sendRequest(body: requestBody) { result in
            switch result {
            case .success(let data):
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
                        completion(.failure(GoogleAIError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Get AI Suggestions
    
    func getAISuggestions(
        businessIdea: BusinessIdea,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let basePrompt = """
        You are a seasoned business mentor with expertise in \(businessIdea.category.lowercased()) ventures. An entrepreneur has selected "\(businessIdea.title)" as their business focus and needs strategic guidance for immediate implementation.
        
        BUSINESS ANALYSIS:
        • Venture: \(businessIdea.title)
        • Concept: \(businessIdea.description)
        • Market Category: \(businessIdea.category)
        • Launch Complexity: \(businessIdea.difficulty)
        • Revenue Target: \(businessIdea.estimatedRevenue)
        • Timeline: \(businessIdea.timeToLaunch)
        
        CONTEXT: This entrepreneur is ready to take action TODAY. They need specific, executable guidance that moves them from idea to implementation. Focus on what they can accomplish in the next 7-30 days.
        
        Provide strategic, actionable coaching in this format:
        
        🚀 IMMEDIATE ACTIONS (Next 7 Days):
        • [Specific task they can complete this week]
        • [Research or validation step with exact methodology]
        • [Initial setup or preparation activity]
        
        � 30-DAY SPRINT GOALS:
        • [Major milestone to achieve within a month]
        • [Key metric to track or customer feedback to gather]
        • [Critical system, process, or asset to develop]
        
        💰 REVENUE GENERATION STRATEGY:
        • [Fastest path to first dollar of revenue]
        • [Pricing strategy based on market positioning]
        • [Customer acquisition approach for this specific business]
        
        🎯 SUCCESS ACCELERATORS:
        • [Competitive advantage to leverage immediately]
        • [Partnership or collaboration opportunity]
        • [Marketing channel that fits their business model]
        
        ⚠️ CRITICAL RISKS TO AVOID:
        • [Most common failure point in this business type]
        • [Resource trap or time waste to avoid]
        • [Market timing or positioning mistake]
        
        🔥 GROWTH CATALYST:
        [One specific strategy that could 2x their business potential if executed well]
        
        Tone: Encouraging yet realistic. Focus on execution over theory. Provide specific examples where possible.
        """
        
        let contextualPrompt = UserContextManager.shared.enhanceAIPrompt(
            basePrompt: basePrompt,
            context: "business_suggestions",
            businessIdea: businessIdea
        )
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contextualPrompt]
                    ]
                ]
            ]
        ]
        
        sendRequest(body: requestBody) { result in
            switch result {
            case .success(let data):
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
                        completion(.failure(GoogleAIError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
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
        
        let progressPhase = determineProgressPhase(progress: currentProgress)
        let focusArea = determineFocusArea(category: businessIdea.category, progress: currentProgress)
        
        let prompt = """
        You are a business coach creating TODAY'S action plan for an entrepreneur.
        
        ENTREPRENEUR STATUS:
        • Business: \(businessIdea.title) (\(businessIdea.category))
        • Concept: \(businessIdea.description)
        • Current Progress: \(currentProgress)% (\(progressPhase))
        • Focus Area: \(focusArea)
        • Difficulty Level: \(businessIdea.difficulty)
        
        CONTEXT: It's a new day and this entrepreneur needs 3 specific tasks that will measurably advance their business TODAY. Each goal should take 30-90 minutes and directly contribute to their current progress phase.
        
        REQUIREMENTS:
        • Goals must be completable in one day
        • Each should move a specific business metric forward
        • Match their current capability level
        • Build momentum toward next major milestone
        • Be concrete with clear success criteria
        
        Generate exactly 3 goals in this format:
        1. [Action verb] [specific task] - [measurable outcome expected]
        2. [Action verb] [specific task] - [measurable outcome expected] 
        3. [Action verb] [specific task] - [measurable outcome expected]
        
        EXAMPLES OF STRONG GOALS:
        - Research 10 potential customers and collect 5 email addresses for validation interviews
        - Create landing page wireframe with 3 key value propositions and 1 call-to-action
        - Write and send cold outreach template to 15 prospects in target market
        
        No headers, explanations, or extra text. Just the 3 numbered goals.
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
        let goalAnalysis = analyzeGoalPatterns(goals: userGoals)
        let motivationalTone = selectMotivationalTone(context: context)
        
        let prompt = """
        You are an executive business coach with a track record of helping entrepreneurs overcome specific challenges and accelerate growth.
        
        CLIENT PROFILE:
        • Current Situation: \(context)
        • Active Goals: \(userGoals.joined(separator: " | "))
        • Goal Pattern Analysis: \(goalAnalysis)
        • Coaching Approach Needed: \(motivationalTone)
        
        COACHING SESSION OBJECTIVE:
        Provide strategic guidance that addresses their immediate challenges while building momentum toward their larger vision. Focus on breakthrough insights and actionable next steps.
        
        RESPONSE FORMAT:

        📊 SITUATIONAL ANALYSIS:
        [Sharp, honest assessment of where they are vs. where they need to be. Identify the key constraint or opportunity.]
        
        🎯 STRATEGIC PRIORITIES (Next 2 Weeks):
        1. [Highest-impact action that unlocks progress on multiple goals]
        2. [Strategic move that builds momentum and confidence] 
        3. [Tactical step that delivers quick win while advancing larger objective]
        
        � BREAKTHROUGH INSIGHT:
        [One counter-intuitive or strategic perspective that could change their approach. Something they might not have considered.]
        
        🚀 MOMENTUM BUILDER:
        [Specific action they can take TODAY that will create positive forward motion and energy]
        
        💪 PERSONAL MOTIVATION:
        [Encouraging message that acknowledges their effort while challenging them to level up. Reference their specific context and goals.]
        
        ⚡ SUCCESS METRIC:
        [One key indicator they should track this week to measure if they're on the right path]
        
        COACHING TONE: \(motivationalTone). Be direct, insightful, and focus on execution over theory.
        """
        
        makeAIRequest(prompt: prompt, completion: completion)
    }
    
    // MARK: - Private Helper Methods
    
    private func buildPrompt(skills: [String], personality: [String], interests: [String]) -> String {
        let skillsText = skills.joined(separator: ", ")
        let personalityText = personality.joined(separator: ", ")
        let interestsText = interests.joined(separator: ", ")
        
        return """
        You are an expert business strategist and entrepreneurship advisor with 20 years of experience helping entrepreneurs launch successful ventures. 
        
        CONTEXT: You're analyzing a unique entrepreneur profile and must generate 5 highly personalized business opportunities that maximize their success potential based on current market trends.
        
        ENTREPRENEUR PROFILE:
        • Core Skills & Expertise: \(skillsText)
        • Personality Traits & Strengths: \(personalityText) 
        • Passions & Interest Areas: \(interestsText)
        
        MISSION: Generate 5 innovative business ideas that synergistically combine their skills, align with their personality, and capitalize on their interests. Each idea should be:
        - Realistic and actionable for 2024-2025
        - Leverages at least 2 of their core skills
        - Matches their personality type
        - Taps into growing market demand
        - Provides clear competitive advantages
        
        OUTPUT FORMAT (CRITICAL - Use this EXACT structure for ALL 5 ideas):
        
        IDEA 1
        Title: [Creative, memorable business name that captures the essence]
        Description: [2-3 compelling sentences explaining the unique value proposition, target market, and why it will succeed in today's economy]
        Category: [MUST be ONE of: Technology, Service, Creative, Retail, Consulting]
        Difficulty: [Easy/Medium/Hard - based on skill requirements and market complexity]
        Revenue: $[X]K - $[Y]K/year
        Launch: [Realistic timeline in weeks/months]
        Skills: [Most relevant skills from their profile]
        Cost: $[X]K - $[Y]K
        Margin: [X]-[Y]%
        Demand: [High/Medium/Low - based on current market research]
        Competition: [High/Medium/Low - realistic market assessment]
        Note: [Personal insight explaining why this specific entrepreneur would excel at this business]
        
        QUALITY GUIDELINES:
        • Make each idea distinctly different in approach and market
        • Include at least one low-risk/high-reward opportunity
        • Include at least one high-growth potential venture
        • Consider remote/digital possibilities for modern flexibility
        • Factor in post-2024 economic and technological trends
        • Ensure realistic financial projections based on current markets
        • Provide specific, actionable concepts (not generic suggestions)
        
        Generate ideas that this entrepreneur can realistically execute and scale successfully.
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
    
    // MARK: - Enhanced Chat Function
    
    func getEnhancedChatResponse(
        message: String,
        businessContext: BusinessIdea?,
        conversationHistory: [String] = [],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let basePrompt = buildChatPrompt(
            userMessage: message,
            businessContext: businessContext,
            history: conversationHistory
        )
        
        // Enhance with user context
        let contextualPrompt = UserContextManager.shared.enhanceAIPrompt(
            basePrompt: basePrompt,
            context: "chat_interaction"
        )
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contextualPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.85,
                "topK": 40,
                "topP": 0.92,
                "maxOutputTokens": 1500
            ]
        ]
        
        sendRequest(body: requestBody) { result in
            switch result {
            case .success(let data):
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = json["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let firstPart = parts.first,
                       let text = firstPart["text"] as? String {
                        
                        // Track conversation in user context
                        let topics = self.extractTopics(from: message)
                        Task { @MainActor in
                            UserContextManager.shared.trackAIConversation(
                                userQuery: message,
                                aiResponse: text,
                                context: businessContext?.title ?? "general_chat",
                                topics: topics
                            )
                        }
                        
                        completion(.success(text))
                    } else {
                        completion(.failure(GoogleAIError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func extractTopics(from message: String) -> [String] {
        let businessKeywords = [
            "marketing", "sales", "revenue", "customers", "product", "service",
            "strategy", "planning", "goals", "metrics", "growth", "scaling",
            "funding", "investment", "competition", "market", "industry",
            "team", "hiring", "operations", "finance", "legal", "technology"
        ]
        
        let lowercaseMessage = message.lowercased()
        return businessKeywords.filter { lowercaseMessage.contains($0) }
    }
    
    private func buildChatPrompt(userMessage: String, businessContext: BusinessIdea?, history: [String]) -> String {
        var systemContext = """
        You are an expert entrepreneurship mentor and business strategist. You provide practical, actionable advice with a focus on real-world execution.
        
        YOUR EXPERTISE AREAS:
        • Business model design and validation
        • Market research and customer development  
        • Financial planning and fundraising strategies
        • Marketing and growth tactics
        • Operational systems and processes
        • Leadership and team building
        
        COMMUNICATION STYLE:
        • Direct and actionable (avoid generic advice)
        • Use specific examples when possible
        • Ask clarifying questions to better help
        • Provide step-by-step guidance
        • Balance encouragement with realistic expectations
        """
        
        if let business = businessContext {
            systemContext += """
            
            USER'S CURRENT BUSINESS FOCUS:
            • Business: \(business.title)
            • Concept: \(business.description)
            • Category: \(business.category)
            • Launch Timeline: \(business.timeToLaunch)
            • Startup Investment: \(business.startupCost)
            
            Keep this business context in mind and provide relevant, specific guidance.
            """
        }
        
        if !history.isEmpty {
            let recentHistory = history.suffix(4).joined(separator: "\n")
            systemContext += """
            
            RECENT CONVERSATION CONTEXT:
            \(recentHistory)
            
            Build on this conversation naturally.
            """
        }
        
        return """
        \(systemContext)
        
        USER MESSAGE: \(userMessage)
        
        Provide helpful, specific guidance based on their question and context. If they're asking about their business, give actionable advice. If they need clarification, ask targeted follow-up questions. Keep responses concise but thorough (2-4 paragraphs typically).
        """
    }

    // Make this public so IslandTimelineViewModel can use it
    func makeAIRequest(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        let contextualPrompt = UserContextManager.shared.enhanceAIPrompt(
            basePrompt: prompt,
            context: "general_ai_request"
        )
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": contextualPrompt]
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
        
        sendRequest(body: requestBody) { result in
            switch result {
            case .success(let data):
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
                        completion(.failure(GoogleAIError.invalidResponse))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func parseBusinessIdeas(from text: String) -> [BusinessIdea] {
        var ideas: [BusinessIdea] = []
        let lines = text.components(separatedBy: "\n")
        var currentIdea: [String: String] = [:]
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Start of a new idea - save the previous one
            if trimmed.uppercased().starts(with: "IDEA") && !currentIdea.isEmpty {
                if let idea = createBusinessIdea(from: currentIdea) {
                    ideas.append(idea)
                }
                currentIdea = [:]
            } else if trimmed.contains(":") && !trimmed.isEmpty {
                // Parse key:value pairs, handling colons in values
                let parts = trimmed.components(separatedBy: ":")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                    let value = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    // Only add non-empty values
                    if !value.isEmpty {
                        currentIdea[key] = value
                    }
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
            // Enhanced regex: handles "1.", "1)", "1 ", bullets "•", and leading dashes/asterisks
            .map { $0.replacingOccurrences(of: "^[0-9]+[.)]?\\s*|^[•]\\s*", with: "", options: .regularExpression) }
        
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
            } else if trimmed.starts(with: "-") || trimmed.starts(with: "•") || trimmed.starts(with: "*") {
                let item = trimmed.replacingOccurrences(of: "^[-•*]\\s*", with: "", options: .regularExpression)
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
    
    private func determineProgressPhase(progress: Int) -> String {
        switch progress {
        case 0...10: return "Ideation & Validation"
        case 11...30: return "Planning & Research" 
        case 31...60: return "Development & Setup"
        case 61...85: return "Launch Preparation"
        case 86...100: return "Growth & Optimization"
        default: return "Active Development"
        }
    }
    
    private func determineFocusArea(category: String, progress: Int) -> String {
        let baseAreas: [String: [String]] = [
            "Technology": ["Product Development", "User Research", "Technical Architecture", "Market Testing"],
            "Service": ["Service Design", "Client Acquisition", "Operations Setup", "Quality Systems"],
            "Creative": ["Portfolio Development", "Brand Building", "Client Pipeline", "Creative Process"],
            "Retail": ["Product Sourcing", "Market Research", "Inventory Planning", "Sales Channels"],
            "Consulting": ["Expertise Positioning", "Client Development", "Service Packaging", "Thought Leadership"]
        ]
        
        let areas = baseAreas[category] ?? ["Business Development", "Market Research", "Operations", "Growth"]
        let phaseIndex = min(progress / 25, areas.count - 1)
        return areas[phaseIndex]
    }
    
    private func analyzeGoalPatterns(goals: [String]) -> String {
        let goalText = goals.joined(separator: " ").lowercased()
        var patterns: [String] = []
        
        if goalText.contains("research") || goalText.contains("analyze") || goalText.contains("study") {
            patterns.append("Research-focused")
        }
        if goalText.contains("build") || goalText.contains("create") || goalText.contains("develop") {
            patterns.append("Creation-oriented")
        }
        if goalText.contains("contact") || goalText.contains("reach") || goalText.contains("network") {
            patterns.append("Relationship-building")
        }
        if goalText.contains("launch") || goalText.contains("start") || goalText.contains("begin") {
            patterns.append("Execution-ready")
        }
        if goalText.contains("improve") || goalText.contains("optimize") || goalText.contains("enhance") {
            patterns.append("Optimization-minded")
        }
        
        return patterns.isEmpty ? "Exploration phase" : patterns.joined(separator: ", ")
    }
    
    private func selectMotivationalTone(context: String) -> String {
        let contextLower = context.lowercased()
        
        if contextLower.contains("stuck") || contextLower.contains("confused") || contextLower.contains("lost") {
            return "Clarifying and direction-setting"
        } else if contextLower.contains("excited") || contextLower.contains("motivated") || contextLower.contains("ready") {
            return "Channeling energy into strategic action"
        } else if contextLower.contains("overwhelmed") || contextLower.contains("busy") || contextLower.contains("stress") {
            return "Prioritization and focus-building"
        } else if contextLower.contains("slow") || contextLower.contains("behind") || contextLower.contains("delay") {
            return "Momentum and acceleration-focused"
        } else {
            return "Balanced growth and strategic thinking"
        }
    }

    private func parseGoalsList(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        return lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            // Enhanced regex: handles "1.", "1)", "1 ", bullets, and dashes
            .map { $0.replacingOccurrences(of: "^[0-9]+[.)]?\\s*|^[-•*]\\s*", with: "", options: .regularExpression) }
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
    
    // MARK: - AI Dynamic Timeline Generation
    
    func generateTimelineIslands(
        businessIdea: BusinessIdea,
        numberOfIslands: Int,
        completion: @escaping (Result<[TimelineIsland], Error>) -> Void
    ) {
        let prompt = """
        You are a business strategy expert creating a dynamic roadmap for an entrepreneur.
        
        BUSINESS CONTEXT:
        • Business: \(businessIdea.title)
        • Category: \(businessIdea.category)
        • Description: \(businessIdea.description)
        • Difficulty: \(businessIdea.difficulty)
        • Launch Timeline: \(businessIdea.timeToLaunch)
        • Required Skills: \(businessIdea.requiredSkills.joined(separator: ", "))
        
        MISSION: Generate exactly \(numberOfIslands) progressive milestones/stages for this business journey. Each stage should:
        • Build logically on the previous stage
        • Have clear, actionable objectives
        • Include realistic timeframes
        • Match the business complexity level
        • Lead naturally to the next stage
        
        OUTPUT FORMAT (JSON):
        [
            {
                "title": "Stage 1: Foundation",
                "description": "Clear description of what happens in this stage",
                "duration": "1-2 weeks",
                "keyTasks": ["Task 1", "Task 2", "Task 3"],
                "successMetrics": ["Metric 1", "Metric 2"],
                "emoji": "🚀"
            }
        ]
        
        GUIDELINES:
        • Stage 1 should always be foundational (research, planning, setup)
        • Middle stages should focus on building, testing, iterating
        • Final stage should be about scaling and optimization
        • Use appropriate emojis that match the stage purpose
        • Keep descriptions concise but specific
        • Ensure logical progression from idea to market success
        
        Return only the JSON array, no additional text or formatting.
        """
        
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let text):
                do {
                    let islands = try self.parseTimelineIslands(from: text)
                    completion(.success(islands))
                } catch {
                    // Fallback to default islands if parsing fails
                    let fallbackIslands = self.generateFallbackTimelineIslands(count: numberOfIslands, businessIdea: businessIdea)
                    completion(.success(fallbackIslands))
                }
            case .failure(_):
                // Fallback to default islands on AI failure
                let fallbackIslands = self.generateFallbackTimelineIslands(count: numberOfIslands, businessIdea: businessIdea)
                completion(.success(fallbackIslands))
            }
        }
    }
    
    private func parseTimelineIslands(from text: String) throws -> [TimelineIsland] {
        // Clean the text to extract JSON
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = extractJSONFromText(cleanText)
        
        guard let data = jsonText.data(using: .utf8) else {
            throw GoogleAIError.serializationFailure
        }
        
        let decoder = JSONDecoder()
        let islands = try decoder.decode([TimelineIsland].self, from: data)
        
        return islands
    }
    
    private func extractJSONFromText(_ text: String) -> String {
        // Try to find JSON array in the text
        if let startRange = text.range(of: "["),
           let endRange = text.range(of: "]", options: .backwards) {
            let jsonRange = startRange.lowerBound..<text.index(after: endRange.lowerBound)
            return String(text[jsonRange])
        }
        
        // If no array brackets found, return the text as is
        return text
    }
    
    private func generateFallbackTimelineIslands(count: Int, businessIdea: BusinessIdea) -> [TimelineIsland] {
        let templates = [
            TimelineIsland(
                title: "🚀 Launch Foundation",
                description: "Research market, validate idea, and set up basic infrastructure",
                duration: "1-2 weeks",
                keyTasks: ["Market research", "Competitor analysis", "Initial setup"],
                successMetrics: ["Research completed", "Plan documented"],
                emoji: "🚀"
            ),
            TimelineIsland(
                title: "🛠️ Build MVP",
                description: "Create minimum viable product and test core functionality",
                duration: "2-4 weeks",
                keyTasks: ["Develop core features", "Create prototypes", "Initial testing"],
                successMetrics: ["MVP completed", "Core features working"],
                emoji: "🛠️"
            ),
            TimelineIsland(
                title: "🎯 Test & Validate",
                description: "Get user feedback and iterate based on real market data",
                duration: "2-3 weeks",
                keyTasks: ["User testing", "Feedback collection", "Product iteration"],
                successMetrics: ["User feedback collected", "Improvements implemented"],
                emoji: "🎯"
            ),
            TimelineIsland(
                title: "📈 Launch & Market",
                description: "Go to market with refined product and marketing strategy",
                duration: "3-4 weeks",
                keyTasks: ["Marketing campaign", "Product launch", "Customer acquisition"],
                successMetrics: ["Product launched", "First customers acquired"],
                emoji: "📈"
            ),
            TimelineIsland(
                title: "⚡ Scale & Optimize",
                description: "Scale operations and optimize for sustainable growth",
                duration: "4-6 weeks",
                keyTasks: ["Process optimization", "Team expansion", "Market growth"],
                successMetrics: ["Revenue targets met", "Operations scaled"],
                emoji: "⚡"
            ),
            TimelineIsland(
                title: "🏆 Growth & Success",
                description: "Achieve sustainable growth and market leadership",
                duration: "Ongoing",
                keyTasks: ["Market expansion", "Innovation", "Team building"],
                successMetrics: ["Market share growth", "Sustainable profitability"],
                emoji: "🏆"
            )
        ]
        
        // Return the requested number of islands
        return Array(templates.prefix(count))
    }
    
    // MARK: - Intelligent Timeline Management
    
    func analyzeAndModifyTimeline(
        currentTimeline: [Island],
        userRequest: String,
        businessIdea: BusinessIdea,
        userContext: String,
        completion: @escaping (Result<TimelineModification, GoogleAIError>) -> Void
    ) {
        let enhancedContext = IntelligentContextManager.shared.buildEnhancedContext(for: userRequest)
        
        let prompt = """
        INTELLIGENT TIMELINE MODIFICATION REQUEST
        
        Business Idea: \(businessIdea.title)
        Industry: \(businessIdea.industry)
        Description: \(businessIdea.description)
        
        Current Timeline:
        \(formatTimelineForAI(currentTimeline))
        
        User Request: \(userRequest)
        
        User Context & Behavioral Insights:
        \(enhancedContext)
        
        Please analyze the user's request and provide a structured timeline modification in JSON format:
        
        {
            "modificationType": "add|remove|reorder|modify|restructure",
            "confidence": 0.9,
            "reasoning": "Explanation of why these changes are recommended",
            "changes": [
                {
                    "type": "add|remove|modify|reorder",
                    "targetId": "island_id_or_null_for_new",
                    "newContent": {
                        "title": "Stage Title",
                        "description": "Detailed description",
                        "duration": "2-3 months",
                        "keyTasks": ["Task 1", "Task 2"],
                        "successMetrics": ["Metric 1", "Metric 2"],
                        "position": {"x": 100, "y": 200},
                        "type": "regular|start|treasure",
                        "emoji": "🚀"
                    },
                    "newPosition": 3
                }
            ],
            "suggestedReminders": [
                {
                    "title": "Check progress on X",
                    "daysFromNow": 7,
                    "type": "milestone"
                }
            ],
            "suggestedNotes": [
                {
                    "title": "Research ideas for X",
                    "content": "Key points to investigate...",
                    "category": "research"
                }
            ]
        }
        
        Guidelines:
        - Only make changes that directly relate to the user's request
        - Maintain logical flow and dependencies between stages
        - Consider the user's experience level and behavioral patterns
        - Suggest practical, actionable timeline modifications
        - Include relevant reminders and notes to support the changes
        - Use appropriate emojis for visual clarity
        """
        
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                do {
                    let modification = try self.parseTimelineModification(response)
                    completion(.success(modification))
                } catch {
                    completion(.failure(.serializationFailure))
                }
            case .failure(let error):
                completion(.failure(error as! GoogleAIError))
            }
        }
    }
    
    func generateSmartSuggestions(
        for businessIdea: BusinessIdea,
        currentProgress: Double,
        completion: @escaping (Result<SmartSuggestions, GoogleAIError>) -> Void
    ) {
        let enhancedContext = IntelligentContextManager.shared.buildEnhancedContext(for: "generate smart suggestions")
        
        let prompt = """
        SMART BUSINESS SUGGESTIONS GENERATOR
        
        Business Idea: \(businessIdea.title)
        Industry: \(businessIdea.industry)
        Description: \(businessIdea.description)
        Current Progress: \(Int(currentProgress * 100))%
        
        User Context & Insights:
        \(enhancedContext)
        
        Generate intelligent, personalized suggestions in JSON format:
        
        {
            "nextActions": [
                {
                    "title": "Action title",
                    "description": "What to do and why",
                    "priority": "high|medium|low",
                    "estimatedTime": "2 hours",
                    "category": "research|planning|execution|networking"
                }
            ],
            "improvementOpportunities": [
                {
                    "area": "Marketing Strategy",
                    "suggestion": "Specific improvement suggestion",
                    "impact": "High potential for customer acquisition"
                }
            ],
            "riskMitigation": [
                {
                    "risk": "Identified risk",
                    "mitigation": "How to address it",
                    "urgency": "high|medium|low"
                }
            ],
            "resourceRecommendations": [
                {
                    "type": "tool|book|course|contact",
                    "name": "Resource name",
                    "reason": "Why this is useful now",
                    "url": "optional_link"
                }
            ],
            "milestoneAdjustments": [
                {
                    "suggestion": "Consider adding a market validation milestone",
                    "reasoning": "Based on your planning patterns"
                }
            ]
        }
        
        Base suggestions on:
        - Current progress and stage
        - User's behavioral patterns and preferences
        - Industry best practices
        - Risk factors and opportunities
        - Available time and resources
        """
        
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                do {
                    let suggestions = try self.parseSmartSuggestions(response)
                    completion(.success(suggestions))
                } catch {
                    completion(.failure(.serializationFailure))
                }
            case .failure(let error):
                completion(.failure(error as! GoogleAIError))
            }
        }
    }
    
    func optimizeTimelineOrder(
        islands: [Island],
        businessIdea: BusinessIdea,
        completion: @escaping (Result<[Island], GoogleAIError>) -> Void
    ) {
        let prompt = """
        TIMELINE OPTIMIZATION REQUEST
        
        Business: \(businessIdea.title) - \(businessIdea.industry)
        
        Current Timeline Order:
        \(formatTimelineForAI(islands))
        
        Please analyze this timeline and suggest the optimal order for maximum business success. Consider:
        - Logical dependencies between stages
        - Risk mitigation timing
        - Resource requirements and availability
        - Market timing and seasonality
        - Funding and cash flow needs
        
        Respond with a JSON array of island IDs in the optimal order:
        {
            "optimizedOrder": ["island_1_id", "island_2_id", "island_3_id", ...],
            "reasoning": "Explanation of the optimization rationale",
            "keyChanges": [
                {
                    "change": "Moved market research before product development",
                    "reason": "Reduces risk of building unwanted features"
                }
            ]
        }
        """
        
        makeAIRequest(prompt: prompt) { result in
            switch result {
            case .success(let response):
                do {
                    let optimization = try self.parseTimelineOptimization(response, islands: islands)
                    completion(.success(optimization))
                } catch {
                    completion(.failure(.serializationFailure))
                }
            case .failure(let error):
                completion(.failure(error as! GoogleAIError))
            }
        }
    }
    
    // MARK: - AI Response Parsing
    
    private func parseTimelineModification(_ response: String) throws -> TimelineModification {
        let jsonData = Data(response.utf8)
        return try JSONDecoder().decode(TimelineModification.self, from: jsonData)
    }
    
    private func parseSmartSuggestions(_ response: String) throws -> SmartSuggestions {
        let jsonData = Data(response.utf8)
        return try JSONDecoder().decode(SmartSuggestions.self, from: jsonData)
    }
    
    private func parseTimelineOptimization(_ response: String, islands: [Island]) throws -> [Island] {
        let jsonData = Data(response.utf8)
        let optimization = try JSONDecoder().decode(TimelineOptimizationResponse.self, from: jsonData)
        
        // Reorder islands based on AI suggestion
        var reorderedIslands: [Island] = []
        for islandId in optimization.optimizedOrder {
            if let island = islands.first(where: { $0.id == islandId }) {
                reorderedIslands.append(island)
            }
        }
        
        // Add any missing islands at the end
        let includedIds = Set(optimization.optimizedOrder)
        let missingIslands = islands.filter { !includedIds.contains($0.id) }
        reorderedIslands.append(contentsOf: missingIslands)
        
        return reorderedIslands
    }
    
    private func formatTimelineForAI(_ islands: [Island]) -> String {
        return islands.enumerated().map { index, island in
            """
            \(index + 1). \(island.title) (ID: \(island.id))
               - Description: \(island.description)
               - Duration: \(island.duration ?? "Not specified")
               - Key Tasks: \(island.keyTasks?.joined(separator: ", ") ?? "None")
               - Success Metrics: \(island.successMetrics?.joined(separator: ", ") ?? "None")
               - Type: \(island.type)
            """
        }.joined(separator: "\n\n")
    }
}

// MARK: - AI Response Models

struct TimelineModification: Codable {
    let modificationType: ModificationType
    let confidence: Double
    let reasoning: String
    let changes: [TimelineChange]
    let suggestedReminders: [SuggestedReminder]
    let suggestedNotes: [SuggestedNote]
    
    enum ModificationType: String, Codable {
        case add, remove, reorder, modify, restructure
    }
}

struct TimelineChange: Codable {
    let type: ChangeType
    let targetId: String?
    let newContent: IslandContent?
    let newPosition: Int?
    
    enum ChangeType: String, Codable {
        case add, remove, modify, reorder
    }
}

struct IslandContent: Codable {
    let title: String
    let description: String
    let duration: String?
    let keyTasks: [String]?
    let successMetrics: [String]?
    let position: Position?
    let type: String?
    let emoji: String?
    
    struct Position: Codable {
        let x: Double
        let y: Double
    }
}

struct SuggestedReminder: Codable {
    let title: String
    let daysFromNow: Int
    let type: String
}

struct SuggestedNote: Codable {
    let title: String
    let content: String
    let category: String
}

struct SmartSuggestions: Codable {
    let nextActions: [NextAction]
    let improvementOpportunities: [ImprovementOpportunity]
    let riskMitigation: [RiskMitigation]
    let resourceRecommendations: [ResourceRecommendation]
    let milestoneAdjustments: [MilestoneAdjustment]
}

struct NextAction: Codable {
    let title: String
    let description: String
    let priority: String
    let estimatedTime: String
    let category: String
}

struct ImprovementOpportunity: Codable {
    let area: String
    let suggestion: String
    let impact: String
}

struct RiskMitigation: Codable {
    let risk: String
    let mitigation: String
    let urgency: String
}

struct ResourceRecommendation: Codable {
    let type: String
    let name: String
    let reason: String
    let url: String?
}

struct MilestoneAdjustment: Codable {
    let suggestion: String
    let reasoning: String
}

struct TimelineOptimizationResponse: Codable {
    let optimizedOrder: [String]
    let reasoning: String
    let keyChanges: [OptimizationChange]
}

struct OptimizationChange: Codable {
    let change: String
    let reason: String
}
