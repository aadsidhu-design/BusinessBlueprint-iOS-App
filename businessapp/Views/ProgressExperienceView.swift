import SwiftUI

struct ProgressExperienceView: View {
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
    }
    
    private var completionRate: Double {
        guard !experienceVM.dailyGoals.isEmpty else { return 0 }
        return Double(experienceVM.dailyGoals.filter { $0.completed }.count) / Double(experienceVM.dailyGoals.count)
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Selector
                    ModernCard(padding: 16) {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp()
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        StatCard(
                            title: "Completed",
                            value: "\(experienceVM.dailyGoals.filter { $0.completed }.count)",
                            icon: "checkmark.circle.fill",
                            color: AppColors.duolingoGreen
                        )
                        .fadeInUp(delay: 0.1)
                        
                        StatCard(
                            title: "Active",
                            value: "\(experienceVM.dailyGoals.filter { !$0.completed }.count)",
                            icon: "target",
                            color: AppColors.primaryOrange
                        )
                        .fadeInUp(delay: 0.2)
                        
                        StatCard(
                            title: "Milestones",
                            value: "\(experienceVM.milestones.filter { $0.completed }.count)",
                            icon: "flag.fill",
                            color: AppColors.brightBlue
                        )
                        .fadeInUp(delay: 0.3)
                        
                        if !experienceVM.dailyGoals.isEmpty {
                            ModernCard(padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Completion Rate")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(completionRate * 100))%")
                                        .font(.title2.bold())
                                        .foregroundColor(AppColors.duolingoGreen)
                                    ProgressView(value: completionRate)
                                        .tint(AppColors.duolingoGreen)
                                }
                            }
                            .fadeInUp(delay: 0.4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Daily Goals
                    if !experienceVM.dailyGoals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Daily Goals")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(experienceVM.dailyGoals) { goal in
                                ModernCard(padding: 16) {
                                    ProgressGoalRow(goal: goal) {
                                        experienceVM.toggleGoalCompletion(goal)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .fadeInUp(delay: 0.5)
                    }
                    
                    // Milestones
                    if !experienceVM.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Milestones")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(experienceVM.milestones) { milestone in
                                ModernCard(padding: 16) {
                                    MilestoneProgressRow(milestone: milestone) {
                                        experienceVM.toggleMilestone(milestone)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .fadeInUp(delay: 0.6)
                    }
                    
                    // Reminders
                    if !experienceVM.reminders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminders")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(experienceVM.reminders) { reminder in
                                ModernCard(padding: 16) {
                                    ReminderProgressRow(reminder: reminder)
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .fadeInUp(delay: 0.7)
                    }
                    
                    // Empty State
                    if experienceVM.dailyGoals.isEmpty && experienceVM.milestones.isEmpty && experienceVM.reminders.isEmpty {
                        ModernCard(padding: 40) {
                            VStack(spacing: 16) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 50))
                                    .foregroundStyle(AppColors.primaryGradient)
                                
                                Text("No Progress Yet")
                                    .font(.headline)
                                
                                Text("Create goals, milestones, and reminders to track your journey")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 24)
                        .fadeInUp()
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await experienceVM.refresh() }
                    HapticManager.shared.trigger(.light)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppColors.primaryOrange)
                }
            }
        }
    }
}

private struct ProgressGoalRow: View {
    let goal: DailyGoal
    let toggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                toggle()
                HapticManager.shared.trigger(goal.completed ? .light : .medium)
            } label: {
                Image(systemName: goal.completed ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(goal.completed ? AppColors.duolingoGreen : AppColors.brightBlue)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(goal.title)
                    .font(.headline)
                    .strikethrough(goal.completed)
                
                if !goal.description.isEmpty {
                    Text(goal.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(goal.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

private struct MilestoneProgressRow: View {
    let milestone: Milestone
    let toggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                toggle()
                HapticManager.shared.trigger(.medium)
            } label: {
                Image(systemName: milestone.completed ? "checkmark.seal.fill" : "seal")
                    .foregroundColor(milestone.completed ? AppColors.duolingoGreen : AppColors.primaryPink)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(milestone.title)
                    .font(.headline)
                    .strikethrough(milestone.completed)
                
                if !milestone.description.isEmpty {
                    Text(milestone.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(milestone.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

private struct ReminderProgressRow: View {
    let reminder: AppReminder
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill((reminder.isCompleted ? AppColors.duolingoGreen : AppColors.primaryOrange).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: reminder.isCompleted ? "bell.slash.fill" : "bell.fill")
                    .font(.title3)
                    .foregroundColor(reminder.isCompleted ? AppColors.duolingoGreen : AppColors.primaryOrange)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                
                if !reminder.message.isEmpty {
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(reminder.scheduledDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ProgressExperienceView()
            .environmentObject(ExperienceViewModel())
    }
}
