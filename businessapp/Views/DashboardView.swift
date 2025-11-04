import SwiftUI
import Charts
import Combine

struct DashboardView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showAddGoal = false
    @State private var showAddMilestone = false
    @State private var showAIAssistant = false
    
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
                    if businessPlanStore.businessIdeas.isEmpty {
                        DashboardEmptyState()
                            .padding(.vertical, 60)
                    } else {
                        VStack(spacing: 24) {
                            // Header with AI Assistant Button
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Your Progress")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    if let ideaTitle = viewModel.selectedBusinessIdea?.title {
                                        Text(ideaTitle)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.75))
                                            .lineLimit(1)
                                    } else {
                                        Text("Business Blueprint")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    showAIAssistant = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "sparkles")
                                        Text("AI")
                                    }
                                    .font(.subheadline.bold())
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
                            .padding(20)
                            
                            // Overall Progress Card
                            ProgressCard(
                                title: "Overall Progress",
                                percentage: viewModel.completionPercentage,
                                icon: "chart.pie.fill"
                            )
                            .padding(.horizontal, 20)
                            
                            // Stats Row
                            HStack(spacing: 16) {
                                StatBox(
                                    number: "\(viewModel.dailyGoals.count)",
                                    label: "Total Goals",
                                    icon: "checkmark.circle.fill"
                                )
                                
                                StatBox(
                                    number: "\(viewModel.completedGoalsCount)",
                                    label: "Completed",
                                    icon: "star.fill"
                                )
                                
                                StatBox(
                                    number: "\(viewModel.milestones.count)",
                                    label: "Milestones",
                                    icon: "flag.fill"
                                )
                            }
                            .padding(.horizontal, 20)
                            
                            // Chart
                            if !viewModel.milestones.isEmpty {
                                MilestoneChartView(milestones: viewModel.milestones)
                                    .padding(20)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                            }
                            
                            // Upcoming Goals
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming Goals")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if viewModel.upcomingGoals.isEmpty {
                                    Text("No upcoming goals. Add one to get started!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                } else {
                                    ForEach(viewModel.upcomingGoals) { goal in
                                        GoalRow(goal: goal, onToggle: {
                                            viewModel.toggleGoalCompletion(goal.id)
                                        })
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            
                            // Milestones List
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Milestones")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if viewModel.milestones.isEmpty {
                                    Text("No milestones yet. Create your first one!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.5))
                                } else {
                                    ForEach(viewModel.milestones.sorted { $0.order < $1.order }) { milestone in
                                        MilestoneRow(milestone: milestone, onToggle: {
                                            viewModel.toggleMilestoneCompletion(milestone.id)
                                        })
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showAddGoal = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                        }
                        
                        Button(action: { showAddMilestone = true }) {
                            Image(systemName: "flag.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalView(isPresented: $showAddGoal, onSave: { goal in
                viewModel.addDailyGoal(goal)
            })
        }
        .sheet(isPresented: $showAddMilestone) {
            AddMilestoneView(isPresented: $showAddMilestone, onSave: { milestone in
                viewModel.addMilestone(milestone)
            })
        }
        .sheet(isPresented: $showAIAssistant) {
            if let idea = viewModel.selectedBusinessIdea {
                AIAssistantView(businessIdea: idea)
            } else {
                // Provide a default business idea for demo
                AIAssistantView(businessIdea: BusinessIdea(
                    id: UUID().uuidString,
                    title: "Your Business Journey",
                    description: "Let AI help you build and grow your business",
                    category: "General",
                    difficulty: "Medium",
                    estimatedRevenue: "$50K-$150K/year",
                    timeToLaunch: "3-6 months",
                    requiredSkills: ["Entrepreneurship", "Marketing"],
                    startupCost: "$5K-$10K",
                    profitMargin: "40-60%",
                    marketDemand: "High",
                    competition: "Medium",
                    createdAt: Date(),
                    userId: "",
                    personalizedNotes: "Start your entrepreneurial journey today"
                ))
            }
        }
        .onAppear {
            viewModel.selectedBusinessIdea = businessPlanStore.selectedBusinessIdea
            if let idea = viewModel.selectedBusinessIdea {
                viewModel.bootstrapDemoData(for: idea)
            }
        }
        .onReceive(businessPlanStore.$businessIdeas) { _ in
            viewModel.selectedBusinessIdea = businessPlanStore.selectedBusinessIdea
            if let idea = viewModel.selectedBusinessIdea {
                viewModel.bootstrapDemoData(for: idea)
            }
        }
        .onReceive(businessPlanStore.$selectedIdeaID) { _ in
            viewModel.selectedBusinessIdea = businessPlanStore.selectedBusinessIdea
            if let idea = viewModel.selectedBusinessIdea {
                viewModel.bootstrapDemoData(for: idea)
            }
        }
    }
}

struct DashboardEmptyState: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb")
                .font(.system(size: 54))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Create Your Blueprint")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text("Complete the AI quiz to unlock a personalized business dashboard, daily goals, and smart milestones.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.white.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

struct ProgressCard: View {
    let title: String
    let percentage: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(percentage)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
            }
            
            ProgressView(value: Double(percentage), total: 100)
                .tint(Color(red: 1, green: 0.6, blue: 0.2))
        }
        .padding(20)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

struct StatBox: View {
    let number: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
            
            Text(number)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

struct MilestoneChartView: View {
    let milestones: [Milestone]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion Timeline")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Chart {
                ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                    BarMark(
                        x: .value("Milestone", String(milestone.title.prefix(10))),
                        y: .value("Progress", milestone.completed ? 100 : 0)
                    )
                    .foregroundStyle(milestone.completed ? Color.green : Color.orange)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 200)
        }
    }
}

struct GoalRow: View {
    let goal: DailyGoal
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(goal.completed ? .green : .white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(goal.completed)
                
                Text(goal.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            PriorityBadge(priority: goal.priority)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct MilestoneRow: View {
    let milestone: Milestone
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(milestone.completed ? .green : .white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(milestone.completed)
                
                Text(milestone.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if milestone.completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct PriorityBadge: View {
    let priority: String
    
    var color: Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        default: return .green
        }
    }
    
    var body: some View {
        Text(priority)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.3))
            .cornerRadius(6)
            .foregroundColor(color)
    }
}

struct AddGoalView: View {
    @Binding var isPresented: Bool
    let onSave: (DailyGoal) -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    
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
                    Form {
                        Section("Goal Details") {
                            TextField("Title", text: $title)
                            TextField("Description", text: $description)
                            Picker("Priority", selection: $priority) {
                                Text("Low").tag("Low")
                                Text("Medium").tag("Medium")
                                Text("High").tag("High")
                            }
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                    .foregroundColor(.white)
                    
                    Button(action: {
                        let goal = DailyGoal(
                            id: UUID().uuidString,
                            businessIdeaId: "",
                            title: title,
                            description: description,
                            dueDate: dueDate,
                            completed: false,
                            priority: priority,
                            createdAt: Date(),
                            userId: ""
                        )
                        onSave(goal)
                        isPresented = false
                    }) {
                        Text("Save Goal")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 1, green: 0.6, blue: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(20)
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Daily Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct AddMilestoneView: View {
    @Binding var isPresented: Bool
    let onSave: (Milestone) -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    
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
                    Form {
                        Section("Milestone Details") {
                            TextField("Title", text: $title)
                            TextField("Description", text: $description)
                            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        }
                    }
                    .foregroundColor(.white)
                    
                    Button(action: {
                        let milestone = Milestone(
                            id: UUID().uuidString,
                            businessIdeaId: "",
                            title: title,
                            description: description,
                            dueDate: dueDate,
                            completed: false,
                            order: 0,
                            createdAt: Date(),
                            userId: ""
                        )
                        onSave(milestone)
                        isPresented = false
                    }) {
                        Text("Save Milestone")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(red: 1, green: 0.6, blue: 0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(20)
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
