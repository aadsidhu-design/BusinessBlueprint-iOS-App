import SwiftUI

struct BusinessIdeasView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = BusinessIdeaViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.1, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Business Ideas")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Personalized opportunities for you")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.yellow)
                                .padding(.horizontal, 20)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(Color(red: 1, green: 0.6, blue: 0.2))
                                .frame(maxHeight: .infinity, alignment: .center)
                                .padding(60)
                        } else if viewModel.businessIdeas.isEmpty {
                            EmptyStateView()
                                .padding(20)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.businessIdeas) { idea in
                                    NavigationLink(destination: IdeaDetailView(idea: idea, viewModel: viewModel)) {
                                        IdeaCard(idea: idea)
                                    }
                                    .simultaneousGesture(TapGesture().onEnded {
                                        viewModel.selectIdea(idea)
                                    })
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.attachStore(businessPlanStore)
        }
    }
}

struct IdeaCard: View {
    let idea: BusinessIdea
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(idea.category)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Description
            Text(idea.description)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            // Key Metrics
            HStack(spacing: 12) {
                MetricBadge(label: "Revenue", value: idea.estimatedRevenue)
                MetricBadge(label: "Timeline", value: idea.timeToLaunch)
                MetricBadge(label: "Demand", value: idea.marketDemand)
            }
            
            // Progress Bar
            if idea.progress > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Progress")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ProgressView(value: Double(idea.progress), total: 100)
                        .tint(Color(red: 1, green: 0.6, blue: 0.2))
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
    }
}

struct MetricBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct IdeaDetailView: View {
    let idea: BusinessIdea
    @ObservedObject var viewModel: BusinessIdeaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showAISuggestions = false
    @State private var aiSuggestions = ""
    @State private var isLoadingAI = false
    
    private var currentIdea: BusinessIdea {
        viewModel.selectedIdea ?? idea
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.1, green: 0.2, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(currentIdea.title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(currentIdea.category)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                            }
                            
                            Spacer()
                            
                            Image(systemName: currentIdea.saved ? "star.fill" : "star")
                                .font(.system(size: 24))
                                .foregroundColor(currentIdea.saved ? .yellow : .white.opacity(0.5))
                        }
                    }
                    .padding(20)
                    
                    // Description
                    DetailSection(title: "Overview", content: currentIdea.description)
                        .padding(.horizontal, 20)
                    
                    // Key Details Grid
                    VStack(spacing: 12) {
                        DetailGrid(
                            items: [
                                ("💰", "Revenue", currentIdea.estimatedRevenue),
                                ("⏱️", "Launch Time", currentIdea.timeToLaunch),
                                ("🎯", "Difficulty", currentIdea.difficulty),
                                ("💵", "Startup Cost", currentIdea.startupCost),
                                ("📊", "Profit Margin", currentIdea.profitMargin),
                                ("📈", "Market Demand", currentIdea.marketDemand),
                                ("🏆", "Competition", currentIdea.competition),
                                ("⚙️", "Skills Required", currentIdea.requiredSkills.joined(separator: ", "))
                            ]
                        )
                    }
                    .padding(20)
                    
                    // Personalized Notes
                    DetailSection(title: "Why This For You?", content: currentIdea.personalizedNotes)
                        .padding(.horizontal, 20)
                    
                    // AI Suggestions Button
                    Button(action: {
                        isLoadingAI = true
                        viewModel.getAISuggestions(for: currentIdea) { suggestions in
                            aiSuggestions = suggestions
                            isLoadingAI = false
                            showAISuggestions = true
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text(isLoadingAI ? "Getting Suggestions..." : "Get AI Suggestions")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .padding(.horizontal, 20)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 1, green: 0.6, blue: 0.2),
                                    Color(red: 1, green: 0.4, blue: 0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 12) {
                        Button(action: { viewModel.saveIdea(currentIdea) }) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Text("Save")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .foregroundColor(.white)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            viewModel.updateProgress(ideaId: currentIdea.id, progress: 25)
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1, green: 0.6, blue: 0.2),
                                        Color(red: 1, green: 0.4, blue: 0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showAISuggestions) {
            AISuggestionsView(isPresented: $showAISuggestions, suggestions: aiSuggestions)
        }
        .onAppear {
            viewModel.selectIdea(idea)
        }
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(1.5)
                .padding(14)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
        }
    }
}

struct DetailGrid: View {
    let items: [(String, String, String)]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(items, id: \.1) { icon, label, value in
                HStack(spacing: 12) {
                    Text(icon)
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(value)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
}

struct AISuggestionsView: View {
    @Binding var isPresented: Bool
    let suggestions: String
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.1, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                
                                Text("AI Suggestions")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(suggestions.isEmpty ? "Next steps to launch your business idea" : suggestions)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(2)
                                .padding(14)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        .padding(20)
                    }
                    
                    Button(action: { isPresented = false }) {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 1, green: 0.6, blue: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Next Steps")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Ideas Yet")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("Complete the quiz to generate personalized business ideas")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    BusinessIdeasView()
}
