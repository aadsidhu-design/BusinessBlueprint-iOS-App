import SwiftUI

struct TimelineFinal: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @State private var selectedIsland: Island?
    @State private var showAIChat = false
    @State private var hasAppeared = false
    @State private var showAIGenerator = false
    @State private var numberOfIslands = 5
    @State private var isGeneratingAI = false
    
    var completedCount: Int {
        Set(timelineVM.journeyProgress.completedIslandIds).count
    }
    
    var totalCount: Int {
        timelineVM.islands.count
    }
    
    var progressPercentage: Int {
        guard totalCount > 0 else { return 0 }
        return Int((Double(completedCount) / Double(totalCount)) * 100)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            mainContentView
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedIsland) { island in
            islandDetailSheet(for: island)
        }
        .sheet(isPresented: $showAIGenerator) {
            aiGeneratorSheet
        }
        .task(id: businessPlanStore.selectedBusinessIdea?.id) {
            await handleBusinessIdeaChange()
        }
        .onAppear {
            // Islands are automatically loaded in IslandTimelineViewModel init()
        }
    }
    
    private var backgroundView: some View {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerView
            timelineScrollView
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Journey")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(completedCount) of \(totalCount) completed")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    showAIGenerator = true
                }) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var timelineScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(timelineVM.islands.enumerated()), id: \.element.id) { index, island in
                    createProgressNode(for: island, at: index)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func createProgressNode(for island: Island, at index: Int) -> some View {
        CleanTimelineNode(
            island: island,
            index: index,
            isCompleted: Set(timelineVM.journeyProgress.completedIslandIds).contains(island.id),
            isCurrent: index == timelineVM.currentIslandIndex,
            isLocked: index > timelineVM.currentIslandIndex,
            isLast: index == timelineVM.islands.count - 1,
            animationDelay: Double(index) * 0.1
        ) {
            handleNodeTap(for: island, at: index)
        }
    }
    
    private func handleNodeTap(for island: Island, at index: Int) {
        if !isLocked(index) {
            HapticManager.shared.trigger(.medium)
            selectedIsland = island
        } else {
            HapticManager.shared.trigger(.warning)
        }
    }
    
    private func islandDetailSheet(for island: Island) -> some View {
        IslandDetailView(
            island: island,
            viewModel: timelineVM,
            onComplete: {
                timelineVM.completeIsland(id: island.id)
                timelineVM.moveToNextIsland()
            }
        )
    }
    
    private func handleBusinessIdeaChange() async {
        if let idea = businessPlanStore.selectedBusinessIdea {
            timelineVM.syncWithDashboard(businessIdea: idea)
            
            if completedCount > 0 && !hasAppeared {
                try? await Task.sleep(nanoseconds: 500_000_000)
                HapticManager.shared.trigger(.success)
            }
            hasAppeared = true
        }
    }
    
    private var aiGeneratorSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                        Text("AI Timeline Generator")
                            .font(.system(size: 24, weight: .bold))
                    }
                    
                    Text("Let AI create a personalized business journey with the perfect number of milestones for your venture")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Number of Stages")
                            .font(.headline)
                        Spacer()
                        Text("\(numberOfIslands)")
                            .font(.title2.bold())
                            .foregroundColor(.purple)
                    }
                    
                    HStack {
                        Button(action: {
                            if numberOfIslands > 3 {
                                numberOfIslands -= 1
                                HapticManager.shared.trigger(.selection)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title2)
                                .foregroundColor(numberOfIslands > 3 ? .purple : .gray)
                        }
                        .disabled(numberOfIslands <= 3)
                        
                        Slider(value: .init(
                            get: { Double(numberOfIslands) },
                            set: { numberOfIslands = Int($0) }
                        ), in: 3...10, step: 1)
                        .accentColor(.purple)
                        
                        Button(action: {
                            if numberOfIslands < 10 {
                                numberOfIslands += 1
                                HapticManager.shared.trigger(.selection)
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(numberOfIslands < 10 ? .purple : .gray)
                        }
                        .disabled(numberOfIslands >= 10)
                    }
                    
                    Text("Recommended: 5-7 stages for most businesses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                Button(action: {
                    generateAITimeline()
                }) {
                    HStack {
                        if isGeneratingAI {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        Text(isGeneratingAI ? "Generating Timeline..." : "Generate AI Timeline")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isGeneratingAI)
            }
            .padding(24)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Close") {
                    showAIGenerator = false
                }
            )
        }
    }
    
    private func generateAITimeline() {
        guard let businessIdea = businessPlanStore.selectedBusinessIdea else { return }
        
        isGeneratingAI = true
        HapticManager.shared.trigger(.medium)
        
        timelineVM.generateAITimelineIslands(
            businessIdea: businessIdea,
            numberOfIslands: numberOfIslands
        ) { success in
            DispatchQueue.main.async {
                isGeneratingAI = false
                
                if success {
                    HapticManager.shared.trigger(.success)
                    showAIGenerator = false
                } else {
                    HapticManager.shared.trigger(.warning)
                    showAIGenerator = false
                }
            }
        }
    }
    
    private func isLocked(_ index: Int) -> Bool {
        return index > timelineVM.currentIslandIndex
    }
}

// MARK: - Clean Timeline Node (Duolingo-style)
private struct CleanTimelineNode: View {
    let island: Island
    let index: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isLocked: Bool
    let isLast: Bool
    let animationDelay: Double
    let onTap: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var showCheckmark = false
    
    var nodeColor: Color {
        if isCompleted {
            return Color.green
        } else if isCurrent {
            return Color.orange
        } else if isLocked {
            return Color.gray.opacity(0.3)
        } else {
            return Color.blue
        }
    }
    
    var iconName: String {
        if isCompleted {
            return "checkmark"
        } else if isLocked {
            return "lock.fill"
        } else {
            return "star.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Left side - Node with connecting line
            VStack(spacing: 0) {
                // Node circle
                Button(action: {
                    if !isLocked {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            scale = 0.9
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                scale = 1.0
                            }
                        }
                        onTap()
                    }
                }) {
                    ZStack {
                        // Outer glow for current
                        if isCurrent && !isLocked {
                            Circle()
                                .fill(nodeColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                        }
                        
                        // Main circle
                        Circle()
                            .fill(nodeColor)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(color: nodeColor.opacity(0.4), radius: 10, x: 0, y: 4)
                        
                        // Icon
                        Image(systemName: iconName)
                            .font(.system(size: isCompleted ? 28 : 24, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(showCheckmark && isCompleted ? 1.2 : 1.0)
                    }
                }
                .disabled(isLocked)
                .scaleEffect(scale)
                .opacity(opacity)
                
                // Connecting line to next node
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    nodeColor.opacity(isCompleted ? 1.0 : 0.3),
                                    Color.gray.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4)
                        .frame(height: 60)
                        .opacity(opacity)
                }
            }
            .frame(width: 80)
            
            // Right side - Content card
            VStack(alignment: .leading, spacing: 8) {
                // Stage number
                Text("Stage \(index + 1)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(nodeColor)
                    .opacity(opacity)
                
                // Island title
                Text(island.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(isLocked ? .secondary : .primary)
                    .lineLimit(2)
                    .opacity(opacity)
                
                // Island description (truncated)
                if !island.description.isEmpty {
                    Text(island.description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .opacity(opacity)
                }
                
                // Status badge
                HStack(spacing: 8) {
                    if isCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    } else if isCurrent {
                        Label("In Progress", systemImage: "arrow.right.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                    } else if isLocked {
                        Label("Locked", systemImage: "lock.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                    } else {
                        Label("Available", systemImage: "circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
                .opacity(opacity)
            }
            .padding(.vertical, 12)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Checkmark pop animation for completed
            if isCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        showCheckmark = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            showCheckmark = false
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    TimelineFinal(timelineVM: IslandTimelineViewModel())
        .environmentObject(BusinessPlanStore())
}
