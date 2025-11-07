import SwiftUI

struct FocusPlannerView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @State private var showAddGoal = false
    @State private var showAddMilestone = false
    
    var body: some View {
        ZStack {
            AppColors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    plannerHeader
                    goalsSection
                    milestoneSection
                    if !timelineVM.reminders.isEmpty {
                        remindersSection
                    }
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Planner")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showAddGoal = true
                        HapticManager.shared.trigger(.medium)
                    } label: {
                        Label("New Goal", systemImage: "checklist")
                    }
                    
                    Button {
                        showAddMilestone = true
                        HapticManager.shared.trigger(.medium)
                    } label: {
                        Label("New Milestone", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            GoalComposerView(isPresented: $showAddGoal) { title, detail, dueDate, priority in
                experienceVM.addGoal(title: title, description: detail, dueDate: dueDate, priority: priority)
            }
        }
        .sheet(isPresented: $showAddMilestone) {
            MilestoneComposerView(isPresented: $showAddMilestone) { title, detail, dueDate in
                experienceVM.addMilestone(title: title, description: detail, dueDate: dueDate)
            }
        }
    }
    
    private var plannerHeader: some View {
        ModernCard(padding: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(selectedIdeaTitle)
                        .font(.title3.bold())
                        .foregroundColor(AppColors.textPrimary)
                    Spacer()
                    ColorfulBadge("\(experienceVM.dailyGoals.filter { !$0.completed }.count) goals active", icon: "target", color: AppColors.primaryOrange)
                }
                
                Text(selectedIdeaSubtitle)
                    .font(.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 16) {
                    PlannerStatCard(value: "\(experienceVM.dailyGoals.count)", label: "Goals")
                    PlannerStatCard(value: "\(experienceVM.milestones.filter { !$0.completed }.count)", label: "Milestones")
                    PlannerStatCard(value: "\(timelineVM.reminders.filter { !$0.isCompleted }.count)", label: "Reminders")
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp()
    }
    
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Goals")
                    .font(.headline)
                Spacer()
                Button("View Timeline") {
                    NotificationCenter.default.post(name: .switchToJourneyTab, object: nil)
                }
                .font(.caption.bold())
                .foregroundColor(AppColors.primary)
            }
            
            if upcomingGoals.isEmpty {
                EmptyPlannerState(icon: "checkmark.seal", title: "No goals yet", message: "Create a goal to keep momentum.")
            } else {
                VStack(spacing: 12) {
                    ForEach(upcomingGoals) { goal in
                        PlannerGoalRow(goal: goal) {
                            experienceVM.toggleGoalCompletion(goal)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.1)
    }
    
    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline)
            
            if experienceVM.milestones.isEmpty {
                EmptyPlannerState(icon: "flag", title: "No milestones", message: "Add milestones to chart the bigger wins.")
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedMilestones) { milestone in
                        PlannerMilestoneRow(milestone: milestone) {
                            experienceVM.toggleMilestone(milestone)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.2)
    }
    
    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminders")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(timelineVM.reminders.sorted { $0.scheduledDate < $1.scheduledDate }) { reminder in
                    PlannerReminderRow(reminder: reminder) {
                        timelineVM.completeReminder(id: reminder.id)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .fadeInUp(delay: 0.3)
    }
    
    private var selectedIdeaTitle: String {
        businessPlanStore.selectedBusinessIdea?.title ?? "Focus Planner"
    }
    
    private var selectedIdeaSubtitle: String {
        businessPlanStore.selectedBusinessIdea?.description ?? "Design your next move with AI-powered guidance."
    }
    
    private var upcomingGoals: [DailyGoal] {
        experienceVM.dailyGoals
            .sorted { lhs, rhs in
                if lhs.completed != rhs.completed {
                    return !lhs.completed
                }
                return lhs.dueDate < rhs.dueDate
            }
    }
    
    private var sortedMilestones: [Milestone] {
        experienceVM.milestones
            .sorted { lhs, rhs in
                if lhs.completed != rhs.completed {
                    return !lhs.completed
                }
                return lhs.order < rhs.order
            }
    }
}

private struct PlannerStatCard: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct PlannerGoalRow: View {
    let goal: DailyGoal
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 14) {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(goal.completed ? AppColors.duolingoGreen : AppColors.textSecondary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(goal.completed)
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                    Text(goal.dueDate, format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Text(goal.priority.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(priorityColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
    
    private var priorityColor: Color {
        switch goal.priority.lowercased() {
        case "high": return AppColors.primaryOrange
        case "medium": return AppColors.brightBlue
        default: return AppColors.textSecondary
        }
    }
}

private struct PlannerMilestoneRow: View {
    let milestone: Milestone
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: milestone.completed ? "flag.checkered" : "flag")
                    .font(.title3)
                    .foregroundColor(milestone.completed ? AppColors.duolingoGreen : AppColors.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(milestone.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(milestone.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(3)
                    Text(milestone.dueDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if milestone.completed {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppColors.duolingoGreen)
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct PlannerReminderRow: View {
    let reminder: AppReminder
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 14) {
                Image(systemName: reminder.isCompleted ? "bell.slash.fill" : "bell.badge.fill")
                    .foregroundColor(reminder.isCompleted ? AppColors.textSecondary : AppColors.primaryOrange)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(reminder.isCompleted)
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                    Text(reminder.scheduledDate, format: .dateTime.weekday(.wide).month().day().hour().minute())
                        .font(.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if reminder.notifyViaCalendar {
                    Image(systemName: "calendar")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(16)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyPlannerState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(AppColors.textSecondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct GoalComposerView: View {
    @Binding var isPresented: Bool
    let onSave: (String, String, Date, String) -> Void
    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    @State private var priority = "High"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Title", text: $title)
                    TextField("Details", text: $detail, axis: .vertical)
                }
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("High").tag("High")
                        Text("Medium").tag("Medium")
                        Text("Low").tag("Low")
                    }
                    .pickerStyle(.segmented)
                }
                Section("Due Date") {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("New Goal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, detail, dueDate, priority)
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct MilestoneComposerView: View {
    @Binding var isPresented: Bool
    let onSave: (String, String, Date) -> Void
    @State private var title = ""
    @State private var detail = ""
    @State private var dueDate = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Milestone") {
                    TextField("Title", text: $title)
                    TextField("Details", text: $detail, axis: .vertical)
                }
                Section("Target Date") {
                    DatePicker("", selection: $dueDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("New Milestone")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, detail, dueDate)
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

extension Notification.Name {
    static let switchToJourneyTab = Notification.Name("SwitchToJourneyTab")
}

#Preview {
    NavigationStack {
        FocusPlannerView(timelineVM: IslandTimelineViewModel())
            .environmentObject(BusinessPlanStore())
            .environmentObject(ExperienceViewModel())
    }
}
