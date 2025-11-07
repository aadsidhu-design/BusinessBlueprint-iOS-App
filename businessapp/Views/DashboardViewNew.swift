import SwiftUI

struct DashboardViewNew: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showAddGoal = false
    @State private var showAIAssistant = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        if businessPlanStore.businessIdeas.isEmpty {
                            emptyState
                        } else {
                            content
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showAddGoal = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.primary)
                        }
                        
                        Button {
                            showAIAssistant = true
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalViewNew(isPresented: $showAddGoal, onSave: { goal in
                viewModel.addDailyGoal(goal)
            })
        }
        .sheet(isPresented: $showAIAssistant) {
            if let idea = viewModel.selectedBusinessIdea {
                AIAssistantViewNew(businessIdea: idea)
            }
        }
        .onAppear {
            viewModel.selectedBusinessIdea = businessPlanStore.selectedBusinessIdea
            if let idea = viewModel.selectedBusinessIdea {
                viewModel.bootstrapDemoData(for: idea)
            }
        }
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primary)
            
            Text("No Business Selected")
                .font(.title2.bold())
                .foregroundColor(AppColors.textPrimary)
            
            Text("Complete the quiz to get personalized business ideas")
                .font(.subheadline)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    var content: some View {
        VStack(spacing: 20) {
            // Business Info
            if let idea = viewModel.selectedBusinessIdea {
                VStack(alignment: .leading, spacing: 12) {
                    Text(idea.title)
                        .font(.title2.bold())
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(idea.description)
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(AppColors.surface)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
            
            // Stats
            HStack(spacing: 12) {
                StatPill(
                    value: "\(viewModel.dailyGoals.count)",
                    label: "Goals",
                    color: AppColors.primary
                )
                
                StatPill(
                    value: "\(viewModel.completedGoalsCount)",
                    label: "Done",
                    color: AppColors.success
                )
                
                StatPill(
                    value: "\(viewModel.milestones.count)",
                    label: "Milestones",
                    color: AppColors.secondary
                )
            }
            .padding(.horizontal, 20)
            
            // Progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Overall Progress")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(viewModel.completionPercentage)%")
                        .font(.title3.bold())
                        .foregroundColor(AppColors.primary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.primary.opacity(0.1))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(AppColors.primary)
                            .frame(width: geo.size.width * CGFloat(viewModel.completionPercentage) / 100, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(20)
            .background(AppColors.surface)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            // Upcoming Goals
            if !viewModel.upcomingGoals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Upcoming Goals")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.upcomingGoals.prefix(3)) { goal in
                            GoalRowNew(goal: goal, onToggle: {
                                viewModel.toggleGoalCompletion(goal.id)
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            
            // Milestones
            if !viewModel.milestones.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Milestones")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 8) {
                        ForEach(viewModel.milestones.sorted { $0.order < $1.order }.prefix(3)) { milestone in
                            MilestoneRowNew(milestone: milestone, onToggle: {
                                viewModel.toggleMilestoneCompletion(milestone.id)
                            })
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct GoalRowNew: View {
    let goal: DailyGoal
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(goal.completed ? AppColors.success : AppColors.textTertiary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(goal.completed)
                    
                    Text(goal.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct MilestoneRowNew: View {
    let milestone: Milestone
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(milestone.completed ? AppColors.success : AppColors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(milestone.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            .padding(16)
            .background(AppColors.surface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AddGoalViewNew: View {
    @Binding var isPresented: Bool
    let onSave: (DailyGoal) -> Void
    @State private var title = ""
    @State private var description = ""
    @State private var priority = "Medium"
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        CleanTextField(title: "Goal Title", text: $title)
                        CleanTextField(title: "Description", text: $description)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            Picker("Priority", selection: $priority) {
                                Text("Low").tag("Low")
                                Text("Medium").tag("Medium")
                                Text("High").tag("High")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                        }
                        
                        Button {
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
                        } label: {
                            Text("Create Goal")
                        }
                        .buttonStyle(ModernButtonStyle())
                        .disabled(title.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct AIAssistantViewNew: View {
    let businessIdea: BusinessIdea
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Text("AI Assistant features coming soon")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(40)
                    }
                }
            }
            .navigationTitle("AI Assistant")
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
