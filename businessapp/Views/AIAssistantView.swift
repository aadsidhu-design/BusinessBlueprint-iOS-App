import SwiftUI
import Combine

struct AIAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: AIAssistantViewModel
    let businessIdea: BusinessIdea
    
    init(businessIdea: BusinessIdea) {
        self.businessIdea = businessIdea
        _viewModel = StateObject(wrappedValue: AIAssistantViewModel(businessIdea: businessIdea))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.96, blue: 0.98),
                    Color(red: 0.98, green: 0.98, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card with Apple White Glass
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.6),
                                                Color.purple.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Assistant")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Powered by Google Gemini")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.orange)
                            Text(businessIdea.title)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                    .glassBackground(.appleWhite)
                    .fadeInUp()
                    
                    // AI Analysis
                    if let analysis = viewModel.businessAnalysis {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Business Analysis")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Viability Score")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(analysis.viabilityScore)%")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(viabilityColor(score: analysis.viabilityScore))
                                    }
                                    
                                    AnimatedProgressRing(
                                        progress: Double(analysis.viabilityScore) / 100.0,
                                        gradient: viabilityScoreGradient(score: analysis.viabilityScore),
                                        size: 100
                                    )
                                    .frame(maxWidth: .infinity)
                                    
                                    if !analysis.strengths.isEmpty {
                                        AnalysisCard(title: "Strengths", items: analysis.strengths, color: AppColors.duolingoGreen)
                                    }
                                    
                                    if !analysis.opportunities.isEmpty {
                                        AnalysisCard(title: "Opportunities", items: analysis.opportunities, color: AppColors.brightBlue)
                                    }
                                    
                                    if !analysis.weaknesses.isEmpty {
                                        AnalysisCard(title: "Weaknesses", items: analysis.weaknesses, color: AppColors.primaryOrange)
                                    }
                                    
                                    if !analysis.threats.isEmpty {
                                        AnalysisCard(title: "Threats", items: analysis.threats, color: .red)
                                    }
                                    
                                    if !analysis.recommendations.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Recommendations")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            ForEach(analysis.recommendations, id: \.self) { rec in
                                                HStack(alignment: .top, spacing: 8) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.orange)
                                                        .font(.caption)
                                                    Text(rec)
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                }
                                            }
                                        }
                                        .glassBackground(.appleWhite)
                                    }
                                }
                            }
                            .glassBackground(.appleWhite)
                            .padding(.horizontal, 24)
                        }
                        .fadeInUp(delay: 0.1)
                    }
                    
                    // Daily Goals
                    if !viewModel.dailyGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI-Generated Daily Goals")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 24)
                            
                            ForEach(Array(viewModel.dailyGoals.enumerated()), id: \.offset) { index, goal in
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 32, height: 32)
                                        Text("\(index + 1)")
                                            .font(.caption.bold())
                                            .foregroundColor(.blue)
                                    }
                                    Text(goal)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .glassBackground(.appleWhite)
                                .padding(.horizontal, 24)
                            }
                        }
                        .fadeInUp(delay: 0.2)
                    }
                    
                    // Personalized Advice
                    if !viewModel.personalizedAdvice.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                Text("Personalized Advice")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            Text(viewModel.personalizedAdvice)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .glassBackground(.appleWhite)
                        .padding(.horizontal, 24)
                        .fadeInUp(delay: 0.3)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        PlayfulButton(
                            title: viewModel.isAnalyzing ? "Analyzing..." : "Analyze Business Idea",
                            icon: "chart.bar.fill",
                            gradient: AppColors.primaryGradient,
                            isLoading: viewModel.isAnalyzing
                        ) {
                            viewModel.analyzeBusinessIdea()
                        }
                        
                        PlayfulButton(
                            title: viewModel.isGeneratingGoals ? "Generating..." : "Generate Daily Goals",
                            icon: "target",
                            gradient: AppColors.successGradient,
                            isLoading: viewModel.isGeneratingGoals
                        ) {
                            viewModel.generateDailyGoals()
                        }
                        
                        PlayfulButton(
                            title: viewModel.isGettingAdvice ? "Getting advice..." : "Get Personalized Advice",
                            icon: "message.fill",
                            gradient: AppColors.blueGradient,
                            isLoading: viewModel.isGettingAdvice
                        ) {
                            viewModel.getPersonalizedAdvice()
                        }
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp(delay: 0.4)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func viabilityColor(score: Int) -> Color {
        if score >= 80 { return AppColors.duolingoGreen }
        if score >= 60 { return AppColors.primaryOrange }
        return .red
    }
    
    private func viabilityScoreGradient(score: Int) -> LinearGradient {
        if score >= 80 {
            return AppColors.successGradient
        } else if score >= 60 {
            return AppColors.primaryGradient
        } else {
            return LinearGradient(colors: [.red, .red.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

private struct AnalysisCard: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        ModernCard(
            borderColor: color.opacity(0.3),
            padding: 16
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(color)
                
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(item)
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - AI Assistant ViewModel

class AIAssistantViewModel: ObservableObject {
    @Published var businessAnalysis: AIBusinessAnalysis?
    @Published var dailyGoals: [String] = []
    @Published var personalizedAdvice: String = ""
    @Published var isAnalyzing = false
    @Published var isGeneratingGoals = false
    @Published var isGettingAdvice = false
    
    let businessIdea: BusinessIdea
    
    init(businessIdea: BusinessIdea) {
        self.businessIdea = businessIdea
    }
    
    func analyzeBusinessIdea() {
        isAnalyzing = true
        
        let userProfile: [String: Any] = [
            "category": businessIdea.category,
            "difficulty": businessIdea.difficulty
        ]
        
        UserContextManager.shared.trackEvent(.aiInteractionStarted, context: [
            "interactionType": "business_analysis",
            "businessIdeaId": businessIdea.id,
            "businessIdeaTitle": businessIdea.title
        ])
        
        GoogleAIService.shared.analyzeBusinessIdea(
            idea: businessIdea,
            userProfile: userProfile
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isAnalyzing = false
                switch result {
                case .success(let analysis):
                    self?.businessAnalysis = analysis
                    UserContextManager.shared.trackEvent(.aiResponseReceived, context: [
                        "interactionType": "business_analysis",
                        "viabilityScore": String(analysis.viabilityScore)
                    ])
                case .failure(let error):
                    print("Error analyzing idea: \(error)")
                    UserContextManager.shared.trackEvent(.aiInteractionFailed, context: [
                        "interactionType": "business_analysis",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
    
    func generateDailyGoals() {
        isGeneratingGoals = true
        
        UserContextManager.shared.trackEvent(.aiInteractionStarted, context: [
            "interactionType": "daily_goals_generation",
            "businessIdeaId": businessIdea.id
        ])
        
        GoogleAIService.shared.generateDailyGoals(
            businessIdea: businessIdea,
            currentProgress: businessAnalysis?.viabilityScore ?? 0
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGeneratingGoals = false
                switch result {
                case .success(let goals):
                    self?.dailyGoals = goals
                    UserContextManager.shared.trackEvent(.aiResponseReceived, context: [
                        "interactionType": "daily_goals_generation",
                        "goalsCount": String(goals.count)
                    ])
                case .failure(let error):
                    print("Error generating goals: \(error)")
                    UserContextManager.shared.trackEvent(.aiInteractionFailed, context: [
                        "interactionType": "daily_goals_generation",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
    
    func getPersonalizedAdvice() {
        isGettingAdvice = true
        
        let context = "Working on: \(businessIdea.title). \(businessIdea.description)"
        
        UserContextManager.shared.trackEvent(.aiInteractionStarted, context: [
            "interactionType": "personalized_advice",
            "businessIdeaId": businessIdea.id
        ])
        
        GoogleAIService.shared.getPersonalizedAdvice(
            context: context,
            userGoals: dailyGoals
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGettingAdvice = false
                switch result {
                case .success(let advice):
                    self?.personalizedAdvice = advice
                    UserContextManager.shared.trackEvent(.aiResponseReceived, context: [
                        "interactionType": "personalized_advice"
                    ])
                case .failure(let error):
                    print("Error getting advice: \(error)")
                    UserContextManager.shared.trackEvent(.aiInteractionFailed, context: [
                        "interactionType": "personalized_advice",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AIAssistantView(businessIdea: BusinessIdea(
            id: UUID().uuidString,
            title: "AI-Powered Consulting",
            description: "Help businesses leverage AI technology",
            category: "Technology",
            difficulty: "Medium",
            estimatedRevenue: "$100K-$250K/year",
            timeToLaunch: "3-6 months",
            requiredSkills: ["AI/ML", "Business", "Communication"],
            startupCost: "$5K-$15K",
            profitMargin: "60-80%",
            marketDemand: "High",
            competition: "Medium",
            createdAt: Date(),
            userId: "",
            personalizedNotes: "Perfect for tech-savvy entrepreneurs"
        ))
    }
}
