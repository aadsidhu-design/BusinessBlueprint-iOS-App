import SwiftUI

struct BusinessIdeasView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = BusinessIdeaViewModel()
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(AppColors.primaryOrange)
                    .scaleEffect(1.5)
            } else if viewModel.businessIdeas.isEmpty {
                EmptyIdeasView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.businessIdeas.enumerated()), id: \.element.id) { index, idea in
                            NavigationLink {
                                IdeaDetailView(idea: idea, viewModel: viewModel)
                            } label: {
                                OldIdeaCard(idea: idea)
                            }
                            .buttonStyle(.plain)
                            .onTapGesture {
                                viewModel.selectIdea(idea)
                            }
                            .fadeInUp(delay: Double(index) * 0.1)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .navigationTitle("Business Ideas")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.attachStore(businessPlanStore)
        }
    }
}

private struct OldIdeaCard: View {
    let idea: BusinessIdea
    @State private var isPressed = false
    
    var body: some View {
        ModernCard(
            borderColor: AppColors.primaryOrange.opacity(0.3),
            padding: 20
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(idea.title)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        ColorfulBadge(idea.category, icon: "tag.fill", color: AppColors.primaryOrange)
                    }
                    
                    Spacer()
                    
                    if idea.progress > 0 {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                                .frame(width: 50, height: 50)
                            
                            Circle()
                                .trim(from: 0, to: Double(idea.progress) / 100.0)
                                .stroke(
                                    AppColors.primaryGradient,
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(idea.progress)%")
                                .font(.caption.bold())
                                .foregroundColor(AppColors.primaryOrange)
                        }
                    } else {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(AppColors.primaryGradient)
                    }
                }
                
                Text(idea.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption)
                        Text(idea.estimatedRevenue)
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.duolingoGreen)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                        Text(idea.timeToLaunch)
                            .font(.caption)
                    }
                    .foregroundColor(AppColors.brightBlue)
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AnimationHelpers.cardTap, value: isPressed)
    }
}

private struct EmptyIdeasView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryOrange.opacity(0.2), AppColors.primaryPink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "lightbulb.slash")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primaryGradient)
            }
            .bounceEntrance()
            
            Text("No Ideas Yet")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("Complete the quiz to generate personalized business ideas")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
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
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Card
                    ModernCard(
                        gradient: AppColors.vibrantGradient,
                        padding: 24
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(currentIdea.title)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    ColorfulBadge(currentIdea.category, icon: "tag.fill", color: .white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .fadeInUp()
                    
                    // Description
                    ModernCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                            
                            Text(currentIdea.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .fadeInUp(delay: 0.1)
                    
                    // Key Details Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        DetailCard(
                            icon: "dollarsign.circle.fill",
                            title: "Revenue",
                            value: currentIdea.estimatedRevenue,
                            color: AppColors.duolingoGreen
                        )
                        
                        DetailCard(
                            icon: "clock.fill",
                            title: "Launch Time",
                            value: currentIdea.timeToLaunch,
                            color: AppColors.brightBlue
                        )
                        
                        DetailCard(
                            icon: "chart.bar.fill",
                            title: "Difficulty",
                            value: currentIdea.difficulty,
                            color: AppColors.primaryOrange
                        )
                        
                        DetailCard(
                            icon: "dollarsign.circle.fill",
                            title: "Startup Cost",
                            value: currentIdea.startupCost,
                            color: AppColors.primaryPink
                        )
                    }
                    .fadeInUp(delay: 0.2)
                    
                    // Additional Details
                    ModernCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            DetailRow(icon: "percent", title: "Profit Margin", value: currentIdea.profitMargin)
                            DetailRow(icon: "arrow.up.right", title: "Market Demand", value: currentIdea.marketDemand)
                            DetailRow(icon: "person.2.fill", title: "Competition", value: currentIdea.competition)
                            
                            if !currentIdea.requiredSkills.isEmpty {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Skills Required", systemImage: "star.fill")
                                        .font(.headline)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(currentIdea.requiredSkills, id: \.self) { skill in
                                                ColorfulBadge(skill, color: AppColors.primaryOrange)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .fadeInUp(delay: 0.3)
                    
                    // Personalized Notes
                    if !currentIdea.personalizedNotes.isEmpty {
                        ModernCard(
                            borderColor: AppColors.primaryOrange.opacity(0.5),
                            padding: 20
                        ) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(AppColors.primaryPink)
                                    Text("Why This For You?")
                                        .font(.headline)
                                }
                                
                                Text(currentIdea.personalizedNotes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .fadeInUp(delay: 0.4)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        PlayfulButton(
                            title: isLoadingAI ? "Loading..." : "Get AI Suggestions",
                            icon: "sparkles",
                            gradient: AppColors.primaryGradient,
                            isLoading: isLoadingAI
                        ) {
                            isLoadingAI = true
                            viewModel.getAISuggestions(for: currentIdea) { suggestions in
                                DispatchQueue.main.async {
                                    self.aiSuggestions = suggestions
                                    self.isLoadingAI = false
                                    self.showAISuggestions = true
                                }
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                viewModel.saveIdea(currentIdea)
                                HapticManager.shared.trigger(.success)
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                    Text("Save")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.brightBlue)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            
                            Button {
                                viewModel.updateProgress(ideaId: currentIdea.id, progress: 25)
                                HapticManager.shared.trigger(.success)
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Start")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppColors.successGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .fadeInUp(delay: 0.5)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(24)
            }
        }
        .navigationTitle("Business Idea")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAISuggestions) {
            AISuggestionsSheet(suggestions: aiSuggestions)
        }
        .onAppear {
            viewModel.selectIdea(idea)
        }
    }
}

private struct DetailCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        ModernCard(
            borderColor: color.opacity(0.3),
            padding: 16
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primaryOrange)
        }
    }
}

private struct AISuggestionsSheet: View {
    let suggestions: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    ModernCard(padding: 24) {
                        Text(suggestions.isEmpty ? "Next steps to launch your business idea" : suggestions)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("AI Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BusinessIdeasView()
    }
}
