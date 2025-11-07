import SwiftUI

struct BrainDumpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var contextManager = IntelligentContextManager.shared
    private let aiService = GoogleAIService.shared
    
    @State private var thoughtsText = ""
    @State private var isProcessing = false
    @State private var showingResult = false
    @State private var generatedIdea: BusinessIdea?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "6366F1"))
                        
                        Text("Brain Dump")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Let your thoughts flow. Don't worry about structure - just write everything that comes to mind.")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                    
                    // Text Editor
                    ZStack(alignment: .topLeading) {
                        if thoughtsText.isEmpty {
                            Text("What's on your mind? Ideas, problems you want to solve, skills you have, industries you're interested in...")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $thoughtsText)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                    }
                    .frame(maxHeight: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    )
                    .padding(.horizontal, 24)
                    
                    // Generate Button
                    Button(action: generateIdea) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            
                            Text(isProcessing ? "Analyzing..." : "Generate Idea")
                                .font(.system(size: 17, weight: .semibold))
                        }
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
                        .shadow(color: Color(hex: "6366F1").opacity(0.3), radius: 12, x: 0, y: 4)
                    }
                    .disabled(thoughtsText.isEmpty || isProcessing)
                    .opacity(thoughtsText.isEmpty ? 0.5 : 1.0)
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
        .sheet(isPresented: $showingResult) {
            if let idea = generatedIdea {
                GeneratedIdeaView(idea: idea, braindumpText: thoughtsText)
            }
        }
    }
    
    private func generateIdea() {
        isProcessing = true
        
        // Record context
        contextManager.recordAction(
            .businessIdeaExplored(idea: thoughtsText, industry: nil),
            metadata: ["type": "braindump", "length": "\(thoughtsText.count)"]
        )
        
        let prompt = """
        Analyze this brain dump and generate a business idea:
        
        \(thoughtsText)
        
        Create a structured business idea with:
        - Name (catchy, memorable)
        - Tagline (one sentence value proposition)
        - Description (2-3 paragraphs)
        - Target market
        - Key problems it solves
        - Unique value proposition
        
        Return as JSON with keys: name, tagline, description, targetMarket, problems (array), valueProposition
        """
        
        aiService.makeAIRequest(prompt: prompt) { result in
            Task { @MainActor in
                isProcessing = false
                
                switch result {
                case .success(let response):
                    if let idea = parseBusinessIdea(from: response, braindump: thoughtsText) {
                        generatedIdea = idea
                        showingResult = true
                    }
                    
                case .failure(let error):
                    print("Error generating idea: \(error)")
                }
            }
        }
    }
    
    private func parseBusinessIdea(from response: String, braindump: String) -> BusinessIdea? {
        // Try to parse JSON from response
        if let jsonStart = response.range(of: "{"),
           let jsonEnd = response.range(of: "}", options: .backwards) {
            let jsonString = String(response[jsonStart.lowerBound...jsonEnd.upperBound])
            
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let name = json["name"] as? String ?? "New Business Idea"
                let tagline = json["tagline"] as? String ?? ""
                let description = json["description"] as? String ?? braindump
                
                return BusinessIdea(
                    id: UUID().uuidString,
                    title: name,
                    description: description,
                    category: "General",
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
                    personalizedNotes: tagline,
                    saved: false,
                    progress: 0
                )
            }
        }
        
        // Fallback: Create idea from response directly
        return BusinessIdea(
            id: UUID().uuidString,
            title: "New Business Idea",
            description: braindump,
            category: "General",
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
            personalizedNotes: "",
            saved: false,
            progress: 0
        )
    }
}

struct GeneratedIdeaView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    
    let idea: BusinessIdea
    let braindumpText: String
    
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Success Icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(Color(hex: "10B981"))
                            .padding(.top, 40)
                        
                        Text("Idea Generated!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Idea Details
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(idea.title)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(idea.personalizedNotes)
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .textCase(.uppercase)
                                
                                Text(idea.description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Category")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .textCase(.uppercase)
                                
                                Text(idea.category)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.horizontal, 24)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: saveIdea) {
                                Text("Save & Create Timeline")
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
                            
                            Button(action: { dismiss() }) {
                                Text("Regenerate")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "6366F1"))
                            }
                        }
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
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
        .alert("Idea Saved!", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your business idea has been saved and a timeline is being generated.")
        }
    }
    
    private func saveIdea() {
        var ideas = businessPlanStore.businessIdeas
        ideas.append(idea)
        businessPlanStore.setBusinessIdeas(ideas)
        businessPlanStore.selectIdea(idea)
        
        // Record context
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