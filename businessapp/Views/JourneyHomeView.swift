import SwiftUI

struct JourneyHomeView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @State private var selectedIsland: Island?
    @State private var showReminderComposer = false
    @State private var showAI = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    heroCard
                    mapSection
                    if let milestone = nextMilestone {
                        milestoneCard(for: milestone)
                    }
                    if !upcomingGoals.isEmpty {
                        goalsSection
                    }
                    quickActions
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Progress Map")
        .navigationBarTitleDisplayMode(.large)
        .task(id: businessPlanStore.selectedBusinessIdea?.id) {
            if let idea = businessPlanStore.selectedBusinessIdea {
                timelineVM.syncWithDashboard(businessIdea: idea)
            }
        }
        .sheet(item: $selectedIsland) { island in
            IslandDetailView(
                island: island,
                viewModel: timelineVM,
                onComplete: {
                    timelineVM.completeIsland(id: island.id)
                    timelineVM.moveToNextIsland()
                }
            )
        }
        .sheet(isPresented: $showAI) {
            NavigationStack {
                AIProgressAssistantView(viewModel: timelineVM)
            }
        }
        .sheet(isPresented: $showReminderComposer) {
            ReminderComposerView(
                isPresented: $showReminderComposer,
                defaultDate: defaultReminderDate
            ) { title, note, date, addToCalendar in
                timelineVM.addReminder(
                    title: title,
                    message: note,
                    scheduledDate: date,
                    addToCalendar: addToCalendar
                )
            }
        }
    }
    
    private var heroCard: some View {
        ModernCard(
            gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            ),
            borderColor: .clear,
            padding: 24
        ) {
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(heroTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next Milestone")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(nextIslandTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 10) {
                        JourneyStatBadge(
                            icon: "checkmark.circle.fill",
                            title: "\(completedStages)",
                            subtitle: "Stages cleared"
                        )
                        JourneyStatBadge(
                            icon: "flag.checkered",
                            title: "\(totalStages)",
                            subtitle: "Total stages"
                        )
                    }
                }
                
                Spacer()
                
                AnimatedProgressRing(
                    progress: completionRate,
                    gradient: AppColors.successGradient,
                    lineWidth: 10,
                    size: 120
                )
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp()
    }
    
    private var mapSection: some View {
        ModernCard(
            gradient: LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    AppColors.brightBlue.opacity(0.65)
                ],
                startPoint: .bottom,
                endPoint: .topTrailing
            ),
            borderColor: Color.white.opacity(0.08),
            padding: 24
        ) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Journey Timeline")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    ColorfulBadge(
                        "\(Int(completionRate * 100))% complete",
                        icon: "sparkles",
                        color: AppColors.primaryOrange
                    )
                }
                
                ProgressMapView(
                    islands: timelineVM.islands,
                    currentIndex: timelineVM.currentIslandIndex,
                    completedIds: Set(timelineVM.journeyProgress.completedIslandIds),
                    onSelect: { island in
                        selectedIsland = island
                    }
                )
                .frame(maxWidth: .infinity)
                
                if let current = currentStageCopy {
                    Text(current)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.1)
    }
    
    private func milestoneCard(for milestone: Milestone) -> some View {
        ModernCard(padding: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.title3)
                        .foregroundColor(AppColors.primaryOrange)
                        .padding(12)
                        .background(AppColors.primaryOrange.opacity(0.12))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Focus Milestone")
                            .font(.headline)
                        Text(milestone.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text(milestone.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Text(milestone.description)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                
                PlayfulButton(
                    title: "Mark Complete",
                    icon: "checkmark.seal.fill",
                    gradient: AppColors.successGradient,
                    isLoading: false,
                    disabled: milestone.completed
                ) {
                    experienceVM.toggleMilestone(milestone)
                }
                .opacity(milestone.completed ? 0.4 : 1.0)
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.2)
    }
    
    private var goalsSection: some View {
        ModernCard(padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Today's Focus")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    Button("View All") {
                        showPlannerTab()
                    }
                    .font(.caption.bold())
                    .foregroundColor(AppColors.primary)
                }
                
                VStack(spacing: 12) {
                    ForEach(upcomingGoals.prefix(3)) { goal in
                        GoalChecklistRow(goal: goal) {
                            experienceVM.toggleGoalCompletion(goal)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.3)
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    JourneyQuickAction(
                        icon: "sparkles",
                        title: "Ask the Coach",
                        subtitle: "Get instant guidance",
                        color: AppColors.primaryOrange
                    ) {
                        showAI = true
                    }
                    
                    JourneyQuickAction(
                        icon: "bell.badge",
                        title: "Schedule Reminder",
                        subtitle: "Stay on track",
                        color: AppColors.brightBlue
                    ) {
                        showReminderComposer = true
                    }
                    
                    JourneyQuickAction(
                        icon: "calendar.badge.exclamationmark",
                        title: "Review Milestones",
                        subtitle: "See what is next",
                        color: AppColors.duolingoGreen
                    ) {
                        showPlannerTab()
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .fadeInUp(delay: 0.4)
    }
    
    private var heroTitle: String {
        if let idea = businessPlanStore.selectedBusinessIdea {
            return idea.title
        }
        return "Design Your Business Adventure"
    }
    
    private var nextIslandTitle: String {
        guard timelineVM.islands.indices.contains(timelineVM.currentIslandIndex) else {
            return "Getting Ready"
        }
        return timelineVM.islands[timelineVM.currentIslandIndex].title
    }
    
    private var currentStageCopy: String? {
        guard timelineVM.islands.indices.contains(timelineVM.currentIslandIndex) else { return nil }
        let island = timelineVM.islands[timelineVM.currentIslandIndex]
        return island.description
    }
    
    private var completionRate: Double {
        guard !timelineVM.islands.isEmpty else { return 0 }
        let completedIds = Set(timelineVM.journeyProgress.completedIslandIds)
        let completed = timelineVM.islands.enumerated().filter { index, island in
            completedIds.contains(island.id) || index < timelineVM.currentIslandIndex
        }.count
        return Double(completed) / Double(timelineVM.islands.count)
    }
    
    private var completedStages: Int {
        Set(timelineVM.journeyProgress.completedIslandIds).count
    }
    
    private var totalStages: Int {
        timelineVM.islands.count
    }
    
    private var nextMilestone: Milestone? {
        experienceVM.milestones
            .filter { !$0.completed }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }
    
    private var upcomingGoals: [DailyGoal] {
        experienceVM.dailyGoals
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var defaultReminderDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    private func showPlannerTab() {
        NotificationCenter.default.post(name: .switchToPlannerTab, object: nil)
    }
}

private struct JourneyStatBadge: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct JourneyQuickAction: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.shared.trigger(.light)
            action()
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(color)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: color.opacity(0.12), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : 1)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AnimationHelpers.buttonPress) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

private struct GoalChecklistRow: View {
    let goal: DailyGoal
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(goal.completed ? AppColors.duolingoGreen : AppColors.textSecondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(goal.completed)
                    Text(goal.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressMapView: View {
    let islands: [Island]
    let currentIndex: Int
    let completedIds: Set<String>
    let onSelect: (Island) -> Void
    @State private var animatePath = false
    
    var body: some View {
        GeometryReader { geo in
            let layout = ProgressMapLayout(size: geo.size, count: islands.count)
            let points = layout.points()
            
            ZStack {
                let basePath = layout.path(points: points)
                basePath
                    .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [0.0001, 18]))
                    .foregroundColor(Color.white.opacity(0.18))
                
                basePath
                    .trim(from: 0, to: animatePath ? 1 : 0.05)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.brightBlue],
                            startPoint: .bottom,
                            endPoint: .top
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [0.0001, 18])
                    )
                    .animation(Animation.easeInOut(duration: 2.6).repeatForever(autoreverses: true), value: animatePath)
                
                ForEach(Array(islands.enumerated()), id: \.element.id) { index, island in
                    if let point = points[safe: index] {
                        let horizontalOffset = layout.offset(for: index)
                        let state = TimelineNodeState(
                            isCurrent: index == currentIndex,
                            isCompleted: completedIds.contains(island.id),
                            isLocked: index > currentIndex && !completedIds.contains(island.id),
                            horizontalOffset: horizontalOffset
                        )
                        
                        TimelineNodeView(island: island, state: state)
                            .position(point)
                            .onTapGesture {
                                guard !state.isLocked else { return }
                                onSelect(island)
                            }
                    }
                }
            }
            .onAppear {
                animatePath = true
            }
        }
        .frame(height: max(CGFloat(islands.count) * 110, 360))
    }
}

private struct TimelineNodeState {
    let isCurrent: Bool
    let isCompleted: Bool
    let isLocked: Bool
    let horizontalOffset: CGFloat
}

private struct TimelineNodeView: View {
    let island: Island
    let state: TimelineNodeState
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            nodeCircle
            nodeLabel
        }
        .frame(width: 220, height: 120)
        .onAppear {
            if state.isCurrent && !state.isCompleted {
                pulse = true
            }
        }
    }
    
    private var nodeCircle: some View {
        let size: CGFloat = state.isCurrent ? 82 : 70
        
        return ZStack {
            Circle()
                .fill(circleBackground)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(circleBorder, lineWidth: state.isCurrent ? 6 : 3)
                        .blur(radius: state.isCurrent ? 1.5 : 0)
                )
                .shadow(color: circleBorder.opacity(0.25), radius: 16, y: 8)
                .scaleEffect(state.isCurrent && !state.isCompleted ? (pulse ? 1.08 : 0.96) : 1)
                .animation(
                    state.isCurrent && !state.isCompleted
                        ? .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
                        : .default,
                    value: pulse
                )
            
            symbol
        }
    }
    
    private var nodeLabel: some View {
        let alignLeft = state.horizontalOffset < -1
        let alignRight = state.horizontalOffset > 1
        let isCentered = !alignLeft && !alignRight
        let stackAlignment: HorizontalAlignment = isCentered ? .center : (alignLeft ? .trailing : .leading)
        
        return VStack(alignment: stackAlignment, spacing: 6) {
            HStack {
                if state.isCurrent {
                    ColorfulBadge("Current", icon: "flame.fill", color: AppColors.primaryOrange)
                } else if state.isCompleted {
                    ColorfulBadge("Complete", icon: "checkmark.seal.fill", color: AppColors.duolingoGreen)
                } else if state.isLocked {
                    ColorfulBadge("Locked", icon: "lock.fill", color: .gray)
                }
                Spacer()
            }
            .opacity(state.isLocked ? 0.7 : 1)
            
            Text(island.title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: isCentered ? .center : (alignLeft ? .trailing : .leading))
            
            Text(island.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: isCentered ? .center : (alignLeft ? .trailing : .leading))
        }
        .frame(width: 160, alignment: isCentered ? .center : (alignLeft ? .trailing : .leading))
        .padding(12)
        .background(Color.white.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .offset(x: isCentered ? 0 : (alignLeft ? -120 : 120))
    }
    
    private var circleBackground: LinearGradient {
        if state.isLocked {
            return LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if state.isCompleted {
            return LinearGradient(colors: [AppColors.duolingoGreen, AppColors.duolingoGreen.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        if state.isCurrent {
            return LinearGradient(colors: [AppColors.primary, AppColors.accent], startPoint: .bottomLeading, endPoint: .topTrailing)
        }
        return LinearGradient(colors: [AppColors.brightBlue.opacity(0.7), AppColors.primary.opacity(0.6)], startPoint: .bottomLeading, endPoint: .topTrailing)
    }
    
    private var circleBorder: Color {
        if state.isLocked { return .gray }
        if state.isCompleted { return AppColors.duolingoGreen }
        if state.isCurrent { return .white }
        return AppColors.brightBlue
    }
    
    private var symbol: some View {
        Group {
            if state.isLocked {
                Image(systemName: "lock.fill")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            } else if state.isCompleted {
                Image(systemName: "checkmark")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
            } else if state.isCurrent {
                Image(systemName: "star.fill")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                    .shadow(color: .white.opacity(0.4), radius: 12, y: 4)
            } else {
                Text(island.type.icon)
                    .font(.title2)
            }
        }
    }
}

private struct ProgressMapLayout {
    let size: CGSize
    let count: Int
    private let offsetPattern: [CGFloat] = [0, -95, 60, -55, 75, -70]
    
    func points() -> [CGPoint] {
        guard count > 0 else { return [] }
        let spacing = size.height / CGFloat(count + 1)
        let centerX = size.width / 2
        
        return (0..<count).map { index in
            let y = size.height - spacing - CGFloat(index) * spacing
            if index == 0 {
                return CGPoint(x: centerX, y: y)
            }
            let rawOffset = offset(for: index)
            let x = (centerX + rawOffset).clamped(to: 60...(size.width - 60))
            return CGPoint(x: x, y: y)
        }
    }
    
    func path(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let control = CGPoint(x: size.width / 2, y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: current, control: control)
        }
        
        return path
    }
    
    func offset(for index: Int) -> CGFloat {
        guard index != 0 else { return 0 }
        return offsetPattern[index % offsetPattern.count]
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension Notification.Name {
    static let switchToPlannerTab = Notification.Name("SwitchToPlannerTab")
}

#Preview {
    NavigationStack {
        JourneyHomeView(timelineVM: IslandTimelineViewModel())
            .environmentObject(BusinessPlanStore())
            .environmentObject(ExperienceViewModel())
    }
}
