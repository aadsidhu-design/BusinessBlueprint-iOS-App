import SwiftUI

struct IslandTimelineView: View {
    @StateObject private var viewModel = IslandTimelineViewModel()
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var selectedIsland: Island?
    @State private var showAIChat = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    ModernCard(
                        gradient: AppColors.vibrantGradient,
                        padding: 24
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(currentJourneyTitle)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(currentStageTitle)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if completionRate > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Progress")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                        Text("\(Int(completionRate * 100))%")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    }
                                    ProgressView(value: completionRate)
                                        .tint(.white)
                                        .scaleEffect(y: 2)
                                }
                            }
                        }
                    }
                    .fadeInUp()
                    
                    // Islands Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Journey Stages")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                            ForEach(Array(viewModel.islands.enumerated()), id: \.element.id) { index, island in
                            IslandCardRow(
                                        island: island,
                                        index: index,
                                isCurrent: index == viewModel.currentIslandIndex,
                                isCompleted: island.isCompleted || viewModel.journeyProgress.completedIslandIds.contains(island.id),
                                isLocked: index > viewModel.currentIslandIndex
                            ) {
                                if !isLocked(index) {
                                            selectedIsland = island
                                }
                            }
                            .padding(.horizontal, 24)
                            .fadeInUp(delay: Double(index) * 0.1)
                        }
                    }
                    
                    // Progress Summary
                    if !viewModel.islands.isEmpty {
                        ModernCard(padding: 20) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Completed")
                                        .font(.headline)
                                    Text("\(completedCount) of \(viewModel.islands.count) stages")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                AnimatedProgressRing(
                                    progress: completionRate,
                                    gradient: AppColors.successGradient,
                                    size: 60
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .fadeInUp()
                    }
                    
                    // AI Assistant Button
                    ModernCard(
                        borderColor: AppColors.primaryOrange.opacity(0.5),
                        padding: 20
                    ) {
                        Button {
                            showAIChat = true
                            HapticManager.shared.trigger(.light)
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryOrange.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "message.fill")
                                        .font(.title3)
                                        .foregroundColor(AppColors.primaryOrange)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ask AI Guide")
                                        .font(.headline)
                                    Text("Get personalized help")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp()
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Journey")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            setupTimeline()
            viewModel.connectToStore(businessPlanStore)
        }
        .sheet(item: $selectedIsland) { island in
            IslandDetailView(
                island: island,
                viewModel: viewModel,
                onComplete: {
                    viewModel.completeIsland(id: island.id)
                    viewModel.moveToNextIsland()
                }
            )
        }
        .sheet(isPresented: $showAIChat) {
            AIProgressAssistantView(viewModel: viewModel)
    }
}

    private var currentJourneyTitle: String {
        if let idea = businessPlanStore.selectedBusinessIdea {
            return idea.title
        }
        return "Your Business Journey"
    }
    
    private var currentStageTitle: String {
        if let stage = viewModel.islands[safe: viewModel.currentIslandIndex] {
            return stage.title
        }
        return viewModel.islands.first?.title ?? "Getting Started"
    }
    
    private var completionRate: Double {
        guard !viewModel.islands.isEmpty else { return 0 }
        return Double(completedCount) / Double(viewModel.islands.count)
    }
    
    private var completedCount: Int {
        if !viewModel.journeyProgress.completedIslandIds.isEmpty {
            return viewModel.journeyProgress.completedIslandIds.count
        }
        let completedByIndex = viewModel.islands.enumerated().filter { index, island in
            index < viewModel.currentIslandIndex || island.isCompleted
        }
        return completedByIndex.count
    }
    
    private func isLocked(_ index: Int) -> Bool {
        index > viewModel.currentIslandIndex
    }
    
    private func setupTimeline() {
        if let idea = businessPlanStore.selectedBusinessIdea {
            viewModel.syncWithDashboard(businessIdea: idea)
        } else if let firstIdea = businessPlanStore.businessIdeas.first {
            businessPlanStore.selectIdea(firstIdea)
            viewModel.syncWithDashboard(businessIdea: firstIdea)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private struct IslandCardRow: View {
    let island: Island
    let index: Int
    let isCurrent: Bool
    let isCompleted: Bool
    let isLocked: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var pulse = false
    
    var body: some View {
        Button {
            onTap()
            HapticManager.shared.trigger(.light)
        } label: {
            ModernCard(
                borderColor: borderColor.opacity(0.5),
                padding: 20
            ) {
                HStack(spacing: 16) {
                    // Status Icon
            ZStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 56, height: 56)
                            .overlay(
                    Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .scaleEffect(isCurrent && !isCompleted ? (pulse ? 1.1 : 1.0) : 1.0)
                        .animation(
                                isCurrent && !isCompleted
                                    ? Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                                    : .default,
                                value: pulse
                            )
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white)
                                .font(.title3)
                        } else if isCompleted {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                        } else {
                            Text(island.type.icon)
                                .font(.title2)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(island.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if isCurrent {
                                ColorfulBadge("Current", icon: "arrow.right.circle.fill", color: AppColors.primaryOrange)
                            }
                        }
                        
                        Text(island.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                        
                        HStack {
                            Text("Stage \(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if isCompleted {
                            Spacer()
                                HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                    Text("Completed")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(AppColors.duolingoGreen)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if !isLocked {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AnimationHelpers.cardTap, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            if isCurrent && !isCompleted {
                pulse = true
            }
        }
    }
    
    private var statusColor: Color {
        if isLocked {
            return .gray
        } else if isCompleted {
            return AppColors.duolingoGreen
        } else if isCurrent {
            return AppColors.primaryOrange
        } else {
            return island.type.color
        }
    }
    
    private var borderColor: Color {
        if isLocked {
            return .gray
        } else if isCompleted {
            return AppColors.duolingoGreen
        } else if isCurrent {
            return AppColors.primaryOrange
        } else {
            return island.type.color
        }
    }
}

#Preview {
    NavigationStack {
        IslandTimelineView()
            .environmentObject(BusinessPlanStore())
    }
}
