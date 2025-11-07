import SwiftUI

struct AIIdeaGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    private let aiService = GoogleAIService.shared
    
    @State private var selectedIndustry = "Technology"
    @State private var selectedProblemArea = "Productivity"
    @State private var additionalContext = ""
    @State private var isGenerating = false
    @State private var generatedIdeas: [BusinessIdea] = []
    @State private var showResults = false
    
    let industries = ["Technology", "Healthcare", "Education", "Finance", "E-commerce", "Food & Beverage", "Real Estate", "Entertainment", "Sustainability", "Other"]
    let problemAreas = ["Productivity", "Communication", "Health & Wellness", "Finance Management", "Learning", "Social Connection", "Transportation", "Housing", "Shopping", "Entertainment"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "F59E0B"))
                            
                            Text("AI Idea Generator")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Answer a few questions and let AI generate personalized business ideas for you")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 40)
                        
                        // Form
                        VStack(spacing: 24) {
                            // Industry Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Industry")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Menu {
                                    ForEach(industries, id: \.self) { industry in
                                        Button(industry) {
                                            selectedIndustry = industry
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedIndustry)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Problem Area Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Problem Area")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Menu {
                                    ForEach(problemAreas, id: \.self) { area in
                                        Button(area) {
                                            selectedProblemArea = area
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedProblemArea)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    .padding(16)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Additional Context
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Additional Context (Optional)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                TextEditor(text: $additionalContext)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .scrollContentBackground(.hidden)
                                    .frame(height: 100)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Generate Button
                        Button(action: generateIdeas) {
                            HStack(spacing: 12) {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                
                                Text(isGenerating ? "Generating Ideas..." : "Generate Ideas")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "F59E0B"), Color(hex: "EF4444")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color(hex: "F59E0B").opacity(0.3), radius: 12, x: 0, y: 4)
                        }
                        .disabled(isGenerating)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "F59E0B"))
                }
            }
        }
        .sheet(isPresented: $showResults) {
            GeneratedIdeasResultView(ideas: generatedIdeas)
        }
    }
    
    private func generateIdeas() {
        isGenerating = true
        
        let prompt = """
        Generate 3 innovative business ideas based on:
        - Industry: \(selectedIndustry)
        - Problem Area: \(selectedProblemArea)
        \(additionalContext.isEmpty ? "" : "- Additional Context: \(additionalContext)")
        
        For each idea, provide:
        - Name (creative and memorable)
        - Tagline (compelling one-liner)
        - Description (2-3 paragraphs explaining the concept)
        - Target Market (specific demographics)
        - Problem (what pain point it solves)
        - Solution (how it addresses the problem)
        
        Return as JSON array with objects containing: name, tagline, description, targetMarket, problem, solution
        """
        
        aiService.makeAIRequest(prompt: prompt) { result in
            Task { @MainActor in
                isGenerating = false
                
                switch result {
                case .success(let response):
                    let ideas = parseIdeas(from: response)
                    if !ideas.isEmpty {
                        generatedIdeas = ideas
                        showResults = true
                    }
                    
                case .failure(let error):
                    print("Error generating ideas: \(error)")
                }
            }
        }
    }
    
    private func parseIdeas(from response: String) -> [BusinessIdea] {
        var ideas: [BusinessIdea] = []
        
        // Try to parse JSON
        if let jsonStart = response.range(of: "["),
           let jsonEnd = response.range(of: "]", options: .backwards) {
            let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
            
            if let data = jsonString.data(using: .utf8),
               let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                
                for json in jsonArray {
                    let idea = BusinessIdea(
                        id: UUID().uuidString,
                        title: json["name"] as? String ?? "Business Idea",
                        description: json["description"] as? String ?? "",
                        category: selectedIndustry,
                        difficulty: "Medium",
                        estimatedRevenue: "$10K-$100K",
                        timeToLaunch: "3-6 months",
                        requiredSkills: [],
                        startupCost: "$1K-$10K",
                        profitMargin: "20-30%",
                        marketDemand: "Medium",
                        competition: "Medium",
                        createdAt: Date(),
                        userId: "",
                        personalizedNotes: json["tagline"] as? String ?? "",
                        saved: false,
                        progress: 0
                    )
                    ideas.append(idea)
                }
            }
        }
        
        return ideas
    }
}

struct GeneratedIdeasResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    
    let ideas: [BusinessIdea]
    @State private var selectedIdeaIndex = 0
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("\(ideas.count) Ideas Generated")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Swipe to explore all ideas")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Tab Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0..<ideas.count, id: \.self) { index in
                                Button(action: {
                                    withAnimation {
                                        selectedIdeaIndex = index
                                    }
                                }) {
                                    Text("Idea \(index + 1)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(selectedIdeaIndex == index ? .white : .white.opacity(0.5))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedIdeaIndex == index ? Color(hex: "6366F1") : Color.white.opacity(0.1))
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 20)
                    
                    // Idea Display
                    TabView(selection: $selectedIdeaIndex) {
                        ForEach(0..<ideas.count, id: \.self) { index in
                            IdeaDetailCard(idea: ideas[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Action Button
                    Button(action: saveCurrentIdea) {
                        Text("Select This Idea")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
        .alert("Idea Saved!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        }
    }
    
    private func saveCurrentIdea() {
        let idea = ideas[selectedIdeaIndex]
        var allIdeas = businessPlanStore.businessIdeas
        allIdeas.append(idea)
        businessPlanStore.setBusinessIdeas(allIdeas)
        businessPlanStore.selectIdea(idea)
        
        IntelligentContextManager.shared.recordBusinessIdeaExplored(
            idea: idea.title,
            industry: idea.category
        )
        
        showSuccess = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            dismiss()
        }
    }
}

struct IdeaDetailCard: View {
    let idea: BusinessIdea
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title & Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.title)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(idea.personalizedNotes)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6366F1"))
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Description
                SectionView(title: "Description", content: idea.description)
                
                // Category
                SectionView(title: "Industry", content: idea.category)
                
                // Market Info
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Market Demand")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(idea.marketDemand)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Competition")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(idea.competition)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(24)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
            
            Text(content)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}