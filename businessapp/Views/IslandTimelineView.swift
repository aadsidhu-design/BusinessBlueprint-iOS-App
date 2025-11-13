import SwiftUI

struct IslandTimelineView: View {
    @StateObject private var viewModel = IslandTimelineViewModel()
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var selectedIsland: Island?
    
    // Milestone data matching the image design
    private let milestones = [
        ("Idea", "lightbulb.fill"),
        ("Research", "magnifyingglass"),
        ("Plan", "doc.text.fill"),
        ("Funding", "dollarsign.circle.fill"),
        ("Launch", "rocket.fill"),
        ("Growth", "chart.line.uptrend.xyaxis")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                            .padding(.top, 20)
                            .padding(.bottom, 60)
                        
                        // Timeline with curved path
                        timelineView
                            .padding(.horizontal, 40)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            setupTimeline()
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
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("Progress Map")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 20)
    }
    
    private var timelineView: some View {
        ZStack {
            // Curved dotted path
            CurvedDottedPath(milestones: milestones, currentIndex: currentMilestoneIndex)
            
            // Milestone circles positioned along the path
            ForEach(Array(milestones.enumerated()), id: \.offset) { index, milestone in
                milestoneCircle(
                    title: milestone.0,
                    icon: milestone.1,
                    index: index,
                    isCompleted: index < currentMilestoneIndex,
                    isCurrent: index == currentMilestoneIndex,
                    isLocked: index > currentMilestoneIndex
                )
                .position(positionForMilestone(at: index))
            }
        }
        .frame(height: 600)
    }
    
    private func milestoneCircle(title: String, icon: String, index: Int, isCompleted: Bool, isCurrent: Bool, isLocked: Bool) -> some View {
        ZStack {
            // Outer ring for current milestone
            if isCurrent {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [mintGreen, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(1.2)
                    .opacity(0.8)
            }
            
            // Main circle
            Circle()
                .fill(circleColor(isCompleted: isCompleted, isCurrent: isCurrent, isLocked: isLocked))
                .frame(width: 60, height: 60)
                .shadow(
                    color: circleColor(isCompleted: isCompleted, isCurrent: isCurrent, isLocked: isLocked).opacity(0.5),
                    radius: isCurrent ? 12 : 6,
                    x: 0,
                    y: 4
                )
            
            // Icon
            if isCurrent {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            } else if isCompleted {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            } else if isLocked {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.6))
            } else {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.gray.opacity(0.8))
            }
        }
        .onTapGesture {
            if !isLocked {
                // Handle milestone tap
            }
        }
    }
    
    private func positionForMilestone(at index: Int) -> CGPoint {
        let totalHeight: CGFloat = 500
        let centerX: CGFloat = 200 // Fixed width instead of screen-dependent
        
        // Create a curved S-path like in the image
        let progress = CGFloat(index) / CGFloat(milestones.count - 1)
        let y = progress * totalHeight + 50
        
        // Curve the x position to create the S-shape
        let amplitude: CGFloat = 80
        let frequency: CGFloat = 1.5
        let x = centerX + sin(progress * frequency * .pi) * amplitude
        
        return CGPoint(x: x, y: y)
    }
    
    private func circleColor(isCompleted: Bool, isCurrent: Bool, isLocked: Bool) -> Color {
        if isCurrent {
            return mintGreen
        } else if isCompleted {
            return mintGreen.opacity(0.8)
        } else if isLocked {
            return Color.gray.opacity(0.4)
        } else {
            return Color.gray.opacity(0.6)
        }
    }
    
    private var mintGreen: Color {
        Color(red: 0.0, green: 0.8, blue: 0.6)
    }
    
    private var currentMilestoneIndex: Int {
        // This would be calculated based on actual progress
        // For now, showing progress at milestone 1 (Research)
        return 1
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

// Custom curved dotted path view
struct CurvedDottedPath: View {
    let milestones: [(String, String)]
    let currentIndex: Int
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let totalHeight: CGFloat = 500
            
            // Draw dotted path connecting all milestones
            for i in 0..<(milestones.count - 1) {
                let startProgress = CGFloat(i) / CGFloat(milestones.count - 1)
                let endProgress = CGFloat(i + 1) / CGFloat(milestones.count - 1)
                
                let startY = startProgress * totalHeight + 50
                let endY = endProgress * totalHeight + 50
                
                // Curve the x positions
                let amplitude: CGFloat = 80
                let frequency: CGFloat = 1.5
                let startX = centerX + sin(startProgress * frequency * .pi) * amplitude
                let endX = centerX + sin(endProgress * frequency * .pi) * amplitude
                
                // Create curved path between points
                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                
                // Add curve control points
                let midY = (startY + endY) / 2
                let controlX1 = startX + (endX - startX) * 0.3
                let controlX2 = startX + (endX - startX) * 0.7
                
                path.addCurve(
                    to: CGPoint(x: endX, y: endY),
                    control1: CGPoint(x: controlX1, y: midY - 20),
                    control2: CGPoint(x: controlX2, y: midY + 20)
                )
                
                // Draw dotted line
                let isCompleted = i < currentIndex
                let color = isCompleted ? 
                    Color(red: 0.0, green: 0.8, blue: 0.6) : 
                    Color.gray.opacity(0.3)
                
                context.stroke(
                    path,
                    with: .color(color),
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        dash: [4, 8]
                    )
                )
                
                // Add small dots along the path
                drawDotsAlongPath(context: context, path: path, color: color)
            }
        }
        .frame(height: 600)
    }
    
    private func drawDotsAlongPath(context: GraphicsContext, path: Path, color: Color) {
        // Add small dots along the path for visual effect
        let pathLength = path.trimmedPath(from: 0, to: 1)
        for _ in stride(from: 0.0, through: 1.0, by: 0.1) {
            if let point = pathLength.currentPoint {
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: point.x - 1,
                        y: point.y - 1,
                        width: 2,
                        height: 2
                    )),
                    with: .color(color.opacity(0.6))
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        IslandTimelineView()
            .environmentObject(BusinessPlanStore())
    }
}