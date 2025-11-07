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
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    if businessPlanStore.businessIdeas.isEmpty {
                        DashboardEmptyState()
                            .padding(.vertical, 60)
                    } else {
                        VStack(spacing: ModernDesign.Spacing.lg) {
                            // Header
                            VStack(alignment: .leading, spacing: ModernDesign.Spacing.sm) {
                                Text("Dashboard")
                                    .font(Typography.title2)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                if let ideaTitle = viewModel.selectedBusinessIdea?.title {
                                    Text(ideaTitle)
                                        .font(Typography.calloutMedium)
                                        .foregroundColor(AppColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
                            .padding(.top, ModernDesign.Spacing.lg)
                            
                            // Stats Row
                            HStack(spacing: ModernDesign.Spacing.md) {
                                SimpleStatCard(
                                    number: "\(viewModel.dailyGoals.count)",
                                    label: "Goals",
                                    icon: "checkmark.circle.fill",
                                    color: AppColors.primary
                                )
                                
                                SimpleStatCard(
                                    number: "\(viewModel.completedGoalsCount)",
                                    label: "Done",
                                    icon: "star.fill",
                                    color: AppColors.success
                                )
                                
                                SimpleStatCard(
                                    number: "\(viewModel.milestones.count)",
                                    label: "Milestones",
                                    icon: "flag.fill",
                                    color: AppColors.secondary
                                )
                            }
                            .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
                            
                            // Overall Progress
                            ProgressCardModern(
                                percentage: viewModel.completionPercentage
                            )
                            .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
                            
                            // Upcoming Goals
                            if !viewModel.upcomingGoals.isEmpty {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                    Text("Upcoming Goals")
                                        .font(Typography.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    VStack(spacing: ModernDesign.Spacing.sm) {
                                        ForEach(viewModel.upcomingGoals.prefix(3)) { goal in
                                            GoalRowModern(goal: goal, onToggle: {
                                                viewModel.toggleGoalCompletion(goal.id)
                                            })
                                        }
                                    }
                                }
                                .padding(ModernDesign.Spacing.lg)
                                .cardStyle()
                                .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
                            }
                            
                            // Milestones
                            if !viewModel.milestones.isEmpty {
                                VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                                    Text("Milestones")
                                        .font(Typography.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    VStack(spacing: ModernDesign.Spacing.sm) {
                                        ForEach(viewModel.milestones.sorted { $0.order < $1.order }.prefix(4)) { milestone in
                                            MilestoneRowModern(milestone: milestone, onToggle: {
                                                viewModel.toggleMilestoneCompletion(milestone.id)
                                            })
                                        }
                                    }
                                }
                                .padding(ModernDesign.Spacing.lg)
                                .cardStyle()
                                .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
                            }
                            
                            Spacer().frame(height: ModernDesign.Spacing.lg)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: ModernDesign.Spacing.md) {
                        Button(action: { showAddGoal = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Button(action: { showAIAssistant = true }) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.secondary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalViewModern(isPresented: $showAddGoal, onSave: { goal in
                viewModel.addDailyGoal(goal)
            })
        }
        .sheet(isPresented: $showAddMilestone) {
            AddMilestoneViewModern(isPresented: $showAddMilestone, onSave: { milestone in
                viewModel.addMilestone(milestone)
            })
        }
        .sheet(isPresented: $showAIAssistant) {
            if let idea = viewModel.selectedBusinessIdea {
                AIAssistantView(businessIdea: idea)
            } else {
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
        VStack(spacing: ModernDesign.Spacing.lg) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 54))
                .foregroundColor(AppColors.primary)
            
            Text("Get Started")
                .font(Typography.title3)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Complete the AI quiz to unlock your personalized business dashboard")
                .font(Typography.callout)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernDesign.Spacing.xl)
        .cardStyle()
        .padding(Edge.Set.horizontal, ModernDesign.Spacing.lg)
    }
}

struct SimpleStatCard: View {
    let number: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(number)
                .font(Typography.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Text(label)
                .font(Typography.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(ModernDesign.Spacing.md)
        .background(color.opacity(0.08))
        .cornerRadius(CornerRadius.lg)
    }
}

struct ProgressCardModern: View {
    let percentage: Int
    
    var body: some View {
        VStack(spacing: ModernDesign.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                    Text("Progress")
                        .font(Typography.calloutMedium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("\(percentage)%")
                        .font(Typography.title2)
                        .foregroundColor(AppColors.textPrimary)
                }
                
                Spacer()
                
                Circle()
                    .trim(from: 0, to: CGFloat(percentage) / 100)
                    .stroke(AppColors.primaryGradient, lineWidth: 6)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(percentage)%")
                            .font(Typography.caption)
                            .foregroundColor(AppColors.textSecondary)
                    )
            }
            
            ProgressView(value: Double(percentage), total: 100)
                .tint(AppColors.primary)
        }
        .padding(ModernDesign.Spacing.lg)
        .cardStyle()
    }
}

struct GoalRowModern: View {
    let goal: DailyGoal
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: ModernDesign.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(goal.completed ? AppColors.success : AppColors.textTertiary)
            }
            
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                Text(goal.title)
                    .font(Typography.bodySemibold)
                    .foregroundColor(AppColors.textPrimary)
                    .strikethrough(goal.completed)
                
                Text(goal.dueDate.formatted(date: .abbreviated, time: .omitted))
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            HStack(spacing: ModernDesign.Spacing.sm) {
                PriorityBadgeModern(priority: goal.priority)
            }
        }
        .padding(ModernDesign.Spacing.md)
        .background(AppColors.surfaceLight)
        .cornerRadius(CornerRadius.md)
    }
}

struct MilestoneRowModern: View {
    let milestone: Milestone
    let onToggle: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: ModernDesign.Spacing.md) {
            Button(action: onToggle) {
                Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(milestone.completed ? AppColors.success : AppColors.primary)
            }
            
            VStack(alignment: .leading, spacing: ModernDesign.Spacing.xs) {
                Text(milestone.title)
                    .font(Typography.bodySemibold)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(milestone.description)
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                Text("Due \(milestone.dueDate, style: .date)")
                    .font(Typography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
        }
        .padding(ModernDesign.Spacing.md)
        .background(AppColors.surfaceLight)
        .cornerRadius(CornerRadius.md)
    }
}

struct PriorityBadgeModern: View {
    let priority: String
    
    var color: Color {
        switch priority {
        case "High": return AppColors.danger
        case "Medium": return AppColors.warning
        default: return AppColors.success
        }
    }
    
    var body: some View {
        Text(priority)
            .font(Typography.caption)
            .padding(Edge.Set.horizontal, ModernDesign.Spacing.sm)
            .padding(.vertical, ModernDesign.Spacing.xs)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.sm)
            .foregroundColor(color)
    }
}

struct AddGoalViewModern: View {
    @Binding var isPresented: Bool
    let onSave: (DailyGoal) -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: ModernDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                        Text("Goal Title")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter goal title", text: $title)
                            .textFieldStyle(AppTextFieldStyle())
                        
                        Text("Description")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, ModernDesign.Spacing.md)
                        
                        TextField("Enter description", text: $description)
                            .textFieldStyle(AppTextFieldStyle())
                        
                        Text("Priority")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, ModernDesign.Spacing.md)
                        
                        Picker("Priority", selection: $priority) {
                            Text("Low").tag("Low")
                            Text("Medium").tag("Medium")
                            Text("High").tag("High")
                        }
                        .pickerStyle(.segmented)
                        
                        Text("Due Date")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, ModernDesign.Spacing.md)
                        
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    .padding(ModernDesign.Spacing.lg)
                    
                    Spacer()
                    
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
                        Text("Create Goal")
                            .buttonStyle(PrimaryButtonStyle(isLoading: false))
                    }
                    .disabled(title.isEmpty)
                    .padding(ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

struct AddMilestoneViewModern: View {
    @Binding var isPresented: Bool
    let onSave: (Milestone) -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: ModernDesign.Spacing.lg) {
                    VStack(alignment: .leading, spacing: ModernDesign.Spacing.md) {
                        Text("Milestone Title")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                        
                        TextField("Enter milestone title", text: $title)
                            .textFieldStyle(AppTextFieldStyle())
                        
                        Text("Description")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, ModernDesign.Spacing.md)
                        
                        TextField("Enter description", text: $description)
                            .textFieldStyle(AppTextFieldStyle())
                        
                        Text("Due Date")
                            .font(Typography.calloutMedium)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(.top, ModernDesign.Spacing.md)
                        
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                    }
                    .padding(ModernDesign.Spacing.lg)
                    
                    Spacer()
                    
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
                        Text("Create Milestone")
                            .buttonStyle(PrimaryButtonStyle(isLoading: false))
                    }
                    .disabled(title.isEmpty)
                    .padding(ModernDesign.Spacing.lg)
                }
            }
            .navigationTitle("Add Milestone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
