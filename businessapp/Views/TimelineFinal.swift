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
        Color(hex: "0F172A")
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
                Text("Timeline")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                
                // Simple Add Button
                Button(action: {
                    showAIGenerator = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color(hex: "6366F1"))
                }
            }
            
            HStack {
                Text("\(completedCount) of \(totalCount) stages completed")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    private var timelineScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(timelineVM.islands.enumerated()), id: \.element.id) { index, island in
                    createProgressNode(for: island, at: index)
                }
            }
            .padding(.top, 40)
            .padding(.bottom, 100)
        }
    }
    
    private func createProgressNode(for island: Island, at index: Int) -> some View {
        ProgressMapNode(
            island: island,
            index: index,
            isCompleted: Set(timelineVM.journeyProgress.completedIslandIds).contains(island.id),
            isCurrent: index == timelineVM.currentIslandIndex,
            isLocked: index > timelineVM.currentIslandIndex,
            isLast: index == timelineVM.islands.count - 1,
            offset: getOffset(for: index),
            animationDelay: Double(index) * 0.15
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
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                HapticManager.shared.trigger(.success)
            }
            hasAppeared = true
        }
    }
    
    private var aiGeneratorSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
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
                
                // Number of Islands Picker
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
                
                // Generate Button
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
                    // Still close the sheet since fallback was used
                    showAIGenerator = false
                }
            }
        }
    }
    
    // Create a zigzag offset pattern like Duolingo
    private func getOffset(for index: Int) -> CGFloat {
        let pattern: [CGFloat] = [0, 60, -60, 80, -80, 40, -40, 100, -100]
        return pattern[index % pattern.count]
    }
    
    // Check if stage is locked
    private func isLocked(_ index: Int) -> Bool {
        return index > timelineVM.currentIslandIndex
    }
}

private struct ProgressMapNode: View {
    let island: Island
    let index: Int
    let isCompleted: Bool
    let isCurrent: Bool
    let isLocked: Bool
    let isLast: Bool
    let offset: CGFloat
    let animationDelay: Double
    let onTap: () -> Void
    
    @State private var pulse = false
    @State private var hasAnimated = false
    @State private var scale: CGFloat = 0.5
    @State private var progressRingValue: CGFloat = 0.0
    @State private var showCompletionEffect = false
    
    var backgroundColor: Color {
        if isCompleted {
            return Color.green
        } else if isCurrent {
            return Color.indigo
        } else if isLocked {
            return Color.gray.opacity(0.3)
        } else {
            return Color.indigo
        }
    }
    
    var borderColor: Color {
        if isCompleted {
            return Color.green
        } else if isCurrent {
            return Color.indigo
        } else {
            return Color.gray.opacity(0.4)
        }
    }
    
    var iconName: String {
        if isCompleted {
            return "star.fill"
        } else if isLocked {
            return "lock.fill"
        } else {
            return "star.fill"
        }
    }
    
    var iconColor: Color {
        if isCompleted {
            return .white
        } else if isCurrent {
            return .white
        } else if isLocked {
            return .gray
        } else {
            return .white
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // The main circle node with progress ring
            Button(action: {
                if !isLocked {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 0.95
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
                    // Progress ring background
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        .frame(width: 90, height: 90)
                    
                    // Animated progress ring
                    Circle()
                        .trim(from: 0, to: progressRingValue)
                        .stroke(
                            borderColor,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0).delay(animationDelay), value: progressRingValue)
                    
                    // Glow effect for current stage
                    if isCurrent && !isLocked {
                        Circle()
                            .fill(backgroundColor.opacity(0.3))
                            .frame(width: 100, height: 100)
                            .scaleEffect(pulse ? 1.2 : 1.0)
                            .opacity(pulse ? 0.5 : 0.8)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(animationDelay + 0.3), value: pulse)
                    }
                    
                    // Main circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: backgroundColor.opacity(isCompleted ? 0.8 : 0.5),
                            radius: isCompleted ? 25 : 20,
                            y: isCompleted ? 10 : 8
                        )
                        .scaleEffect(scale)
                    
                    // Completion sparkle effect
                    if showCompletionEffect {
                        ForEach(0..<8, id: \.self) { i in
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(i) * .pi / 4) * 50,
                                    y: sin(Double(i) * .pi / 4) * 50
                                )
                                .opacity(showCompletionEffect ? 0 : 1)
                                .scaleEffect(showCompletionEffect ? 2 : 0.5)
                                .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: showCompletionEffect)
                        }
                    }
                    
                    // Icon with enhanced animations
                    Image(systemName: iconName)
                        .font(.system(size: isCompleted ? 32 : 28, weight: .bold))
                        .foregroundColor(iconColor)
                        .scaleEffect(scale * (pulse && isCurrent ? 1.1 : 1.0))
                        .rotationEffect(.degrees(isCompleted && hasAnimated ? 360 : 0))
                        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(animationDelay + 0.2), value: scale)
                }
            }
            .disabled(isLocked)
            .offset(x: offset)
            .onAppear {
                // Staggered entrance animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay)) {
                    scale = 1.0
                }
                
                // Animate progress ring
                DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.3) {
                    if isCompleted {
                        progressRingValue = 1.0
                    } else if isCurrent {
                        progressRingValue = 0.7 // Partial progress for current
                    } else if !isLocked {
                        progressRingValue = 0.3 // Small progress for available
                    }
                }
                
                // Start pulsing for current stage
                if isCurrent {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.5) {
                        pulse = true
                    }
                }
                
                // Completion celebration
                if isCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay + 0.8) {
                        showCompletionEffect = true
                        withAnimation(.easeInOut(duration: 1.0)) {
                            hasAnimated = true
                        }
                        // Hide sparkles after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showCompletionEffect = false
                        }
                    }
                }
            }
            
            // Stage label
            Text("Stage \(index + 1)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(isLocked ? .gray : .white.opacity(0.8))
                .offset(x: offset * 0.3)
                .scaleEffect(scale * 0.9)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(animationDelay + 0.4), value: scale)
            
            // Island title (truncated)
            Text(island.title)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(isLocked ? .gray.opacity(0.6) : .white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 80)
                .offset(x: offset * 0.2)
                .scaleEffect(scale * 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(animationDelay + 0.5), value: scale)
            
            // Enhanced dotted path to next node
            if !isLast {
                DottedPath(
                    isCompleted: isCompleted,
                    offset: offset,
                    nextOffset: getNextOffset(),
                    animationDelay: animationDelay
                )
            }
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
    
    private func getNextOffset() -> CGFloat {
        let pattern: [CGFloat] = [0, 60, -60, 80, -80, 40, -40, 100, -100]
        return pattern[(index + 1) % pattern.count]
    }
}

private struct DottedPath: View {
    let isCompleted: Bool
    let offset: CGFloat
    let nextOffset: CGFloat
    let animationDelay: Double
    
    @State private var animatedDots: [Bool] = Array(repeating: false, count: 12)
    @State private var filledDots: [Bool] = Array(repeating: false, count: 12)
    
    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { index in
                ZStack {
                    // Background dot
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: dotSize(for: index), height: dotSize(for: index))
                        .offset(x: getDotOffset(for: index))
                        .scaleEffect(animatedDots[index] ? 1.0 : 0.3)
                        .opacity(animatedDots[index] ? 1.0 : 0.3)
                    
                    // Filled dot that appears progressively
                    if filledDots[index] {
                        Circle()
                            .fill(dotFillColor(for: index))
                            .frame(width: dotSize(for: index), height: dotSize(for: index))
                            .offset(x: getDotOffset(for: index))
                            .scaleEffect(1.2)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: filledDots[index])
                    }
                }
            }
        }
        .frame(height: 90)
        .onAppear {
            // Show background dots first
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDelay) {
                withAnimation(.easeOut(duration: 0.6)) {
                    animatedDots = Array(repeating: true, count: 12)
                }
            }
            
            // Fill dots progressively if completed
            if isCompleted {
                fillDotsProgressively()
            }
        }
    }
    
    private func dotFillColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .blue, .indigo, .purple, .pink]
        return colors[index % colors.count].opacity(0.9)
    }
    
    private func dotSize(for index: Int) -> CGFloat {
        // Vary dot sizes for visual interest with bigger range
        let sizes: [CGFloat] = [3, 5, 4, 6, 5, 4, 5, 3, 4, 5, 6, 4]
        return sizes[index % sizes.count]
    }
    
    private func getDotOffset(for index: Int) -> CGFloat {
        // Create a smooth curved path from current to next offset
        let progress = CGFloat(index) / 11.0
        let curveIntensity: CGFloat = 0.85
        
        // Enhanced bezier curve calculation for smoother path
        let controlPoint1 = offset + (nextOffset - offset) * 0.25 + (offset > nextOffset ? -35 : 35)
        let controlPoint2 = offset + (nextOffset - offset) * 0.75 + (offset > nextOffset ? 25 : -25)
        
        let t = progress
        let point = pow(1 - t, 3) * offset +
                   3 * pow(1 - t, 2) * t * controlPoint1 +
                   3 * (1 - t) * pow(t, 2) * controlPoint2 +
                   pow(t, 3) * nextOffset
        
        return point * curveIntensity
    }
    
    private func fillDotsProgressively() {
        for index in 0..<12 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08 + animationDelay + 0.8) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    filledDots[index] = true
                }
            }
        }
    }
}

#Preview {
    TimelineFinal(timelineVM: IslandTimelineViewModel())
        .environmentObject(BusinessPlanStore())
}

