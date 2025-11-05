import SwiftUI

struct IslandTimelineView: View {
    @StateObject private var viewModel = IslandTimelineViewModel()
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var selectedIsland: Island?
    @State private var showAIChat = false
    @State private var scrollOffset: CGFloat = 0
    @State private var animateWaves = false
    
    var body: some View {
        ZStack {
            // Ocean Background
            OceanBackgroundView(animateWaves: $animateWaves)
            
            // Island Timeline
            ScrollView {
                ZStack {
                    // Path connecting islands
                    IslandPathView(islands: viewModel.islands)
                        .stroke(
                            Color.white.opacity(0.3),
                            style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                        )
                        .padding(40)
                    
                    // Boat animation
                    BoatView()
                        .position(viewModel.boatPosition)
                        .animation(.spring(response: 1.0, dampingFraction: 0.6), value: viewModel.boatPosition)
                    
                    // Islands
                    ForEach(Array(viewModel.islands.enumerated()), id: \.element.id) { index, island in
                        IslandNodeView(
                            island: island,
                            isUnlocked: index <= viewModel.currentIslandIndex,
                            isCurrent: index == viewModel.currentIslandIndex
                        )
                        .position(island.position)
                        .onTapGesture {
                            if index <= viewModel.currentIslandIndex {
                                selectedIsland = island
                            }
                        }
                    }
                }
                .frame(height: 600)
            }
            
            // Top Bar
            VStack {
                TopBarView(
                    currentIsland: viewModel.currentIslandIndex + 1,
                    totalIslands: viewModel.islands.count,
                    onAITap: { showAIChat = true }
                )
                .padding()
                
                Spacer()
            }
            
            // Bottom progress indicator
            VStack {
                Spacer()
                
                ProgressIndicatorView(
                    completed: viewModel.journeyProgress.completedIslandIds.count,
                    total: viewModel.islands.count
                )
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
                .padding()
            }
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
        .onAppear {
            setupTimeline()
            animateWaves = true
            // Connect to store for real-time updates
            viewModel.connectToStore(businessPlanStore)
        }
    }
    
    private func setupTimeline() {
        guard let businessIdea = businessPlanStore.selectedBusinessIdea else {
            // If no selected idea, use first available or return
            guard let firstIdea = businessPlanStore.businessIdeas.first else { return }
            viewModel.syncWithDashboard(businessIdea: firstIdea)
            if let firstIsland = viewModel.islands.first {
                viewModel.boatPosition = firstIsland.position
            }
            return
        }
        
        // Generate islands from business plan if not already set
        if viewModel.islands.count <= 3 {
            viewModel.syncWithDashboard(businessIdea: businessIdea)
        }
        
        // Set initial boat position
        if let firstIsland = viewModel.islands.first {
            viewModel.boatPosition = firstIsland.position
        }
    }
    
    // This function is no longer needed since ViewModel handles goal creation
}

// MARK: - Ocean Background
struct OceanBackgroundView: View {
    @Binding var animateWaves: Bool
    
    var body: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.3, blue: 0.5),
                    Color(red: 0.2, green: 0.5, blue: 0.7),
                    Color(red: 0.3, green: 0.6, blue: 0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Animated waves
            WaveShape(offset: animateWaves ? 350 : 0)
                .fill(Color.white.opacity(0.1))
                .frame(height: 200)
                .offset(y: animateWaves ? -50 : 0)
                .animation(
                    Animation.easeInOut(duration: 3).repeatForever(autoreverses: true),
                    value: animateWaves
                )
            
            WaveShape(offset: animateWaves ? 0 : 350)
                .fill(Color.white.opacity(0.05))
                .frame(height: 200)
                .offset(y: 50)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: animateWaves
                )
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height / 2))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset / width) * .pi * 4)
            let y = height / 2 + sine * 20
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Island Path
struct IslandPathView: Shape {
    let islands: [Island]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !islands.isEmpty else { return path }
        
        path.move(to: islands[0].position)
        
        for island in islands.dropFirst() {
            path.addLine(to: island.position)
        }
        
        return path
    }
}

// MARK: - Island Node
struct IslandNodeView: View {
    let island: Island
    let isUnlocked: Bool
    let isCurrent: Bool
    
    @State private var bounce = false
    
    var body: some View {
        ZStack {
            // Island base (circle)
            Circle()
                .fill(
                    isUnlocked ?
                    LinearGradient(
                        colors: [island.type.color, island.type.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray, Color.gray.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: isCurrent ? island.type.color.opacity(0.6) : .clear, radius: 20)
            
            // Island icon
            Text(island.type.icon)
                .font(.system(size: 40))
                .scaleEffect(bounce ? 1.1 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: bounce
                )
            
            // Completion checkmark
            if island.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                    .background(Circle().fill(Color.white))
                    .offset(x: 30, y: -30)
            }
            
            // Lock for unreached islands
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
        }
        .overlay(
            // Island title
            Text(island.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .offset(y: 55)
        )
        .scaleEffect(isCurrent ? 1.15 : 1.0)
        .onAppear {
            if isCurrent {
                bounce = true
            }
        }
    }
}

// MARK: - Boat View
struct BoatView: View {
    @State private var rock = false
    
    var body: some View {
        Text("⛵")
            .font(.system(size: 40))
            .rotationEffect(.degrees(rock ? -5 : 5))
            .animation(
                Animation.easeInOut(duration: 1).repeatForever(autoreverses: true),
                value: rock
            )
            .onAppear {
                rock = true
            }
    }
}

// MARK: - Top Bar
struct TopBarView: View {
    let currentIsland: Int
    let totalIslands: Int
    let onAITap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Journey")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Island \(currentIsland) of \(totalIslands)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                onAITap()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI Guide")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let completed: Int
    let total: Int
    
    var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.yellow)
                
                Text("\(completed) / \(total) Islands")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            ProgressView(value: progress)
                .tint(.yellow)
                .scaleEffect(y: 2)
        }
        .padding()
    }
}

#Preview {
    IslandTimelineView()
        .environmentObject(BusinessPlanStore())
}
