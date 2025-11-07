import SwiftUI

struct HomeExperienceView: View {
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var showAddGoal = false
    @State private var showAddNote = false
    @State private var newGoalTitle = ""
    @State private var newGoalDetails = ""
    @State private var newGoalPriority = "Medium"
    @State private var newGoalDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var newNoteText = ""
    
    private var firstName: String {
        businessPlanStore.userProfile?.firstName ?? "there"
    }
    
    private var selectedIdea: BusinessIdea? {
        businessPlanStore.selectedBusinessIdea
    }
    
    private var completionRate: Double {
        guard !experienceVM.islands.isEmpty else { return 0 }
        let completed = Double(experienceVM.journeyProgress.completedIslandIds.count)
        let total = Double(experienceVM.islands.count)
        return max(0, min(1, completed / total))
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Card
                    ModernCard(
                        gradient: AppColors.vibrantGradient,
                        padding: 24
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hey, \(firstName)! 👋")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    if let idea = selectedIdea {
                                        Text(idea.title)
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        if idea.progress > 0 {
                                            VStack(alignment: .leading, spacing: 4) {
                                                HStack {
                                                    Text("Progress")
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.8))
                                                    Spacer()
                                                    Text("\(idea.progress)%")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.white)
                                                }
                                                ProgressView(value: Double(idea.progress), total: 100)
                                                    .tint(.white)
                                                    .scaleEffect(y: 2)
                                            }
                                            .padding(.top, 4)
                                        }
                                    } else {
                                        Text("Choose a business idea to begin")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .fadeInUp()
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        StatCard(
                            title: "Goals",
                            value: "\(experienceVM.dailyGoals.count)",
                            icon: "target",
                            color: AppColors.primaryOrange
                        )
                        .fadeInUp(delay: 0.1)
                        
                        StatCard(
                            title: "Milestones",
                            value: "\(experienceVM.milestones.filter { !$0.completed }.count)",
                            icon: "flag.fill",
                            color: AppColors.brightBlue
                        )
                        .fadeInUp(delay: 0.2)
                        
                        StatCard(
                            title: "Notes",
                            value: "\(experienceVM.notes.count)",
                            icon: "note.text",
                            color: AppColors.primaryPink
                        )
                        .fadeInUp(delay: 0.3)
                        
                        if completionRate > 0 {
                            ModernCard(padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "map.fill")
                                            .font(.title3)
                                            .foregroundColor(AppColors.duolingoGreen)
                                        Spacer()
                                        Text("\(Int(completionRate * 100))%")
                                            .font(.title2.bold())
                                            .foregroundColor(AppColors.duolingoGreen)
                                    }
                                    
                                    Text("Journey")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    ProgressView(value: completionRate)
                                        .tint(AppColors.duolingoGreen)
                                }
                            }
                            .fadeInUp(delay: 0.4)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ActionCard(
                                    title: "Add Goal",
                                    subtitle: "Set a new target",
                                    icon: "plus.circle.fill",
                                    color: AppColors.primaryOrange
                                ) {
                                    showAddGoal = true
                                }
                                .frame(width: 180)
                                
                                ActionCard(
                                    title: "Add Note",
                                    subtitle: "Capture thoughts",
                                    icon: "square.and.pencil",
                                    color: AppColors.brightBlue
                                ) {
                                    showAddGoal = true
                                }
                                .frame(width: 180)
                                
                                ActionCard(
                                    title: "View Journey",
                                    subtitle: "See progress",
                                    icon: "map.fill",
                                    color: AppColors.duolingoGreen
                                ) {
                                    // Navigation handled via NavigationLink in tab
                                }
                                .frame(width: 180)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .fadeInUp(delay: 0.5)
                    
                    // Upcoming Milestones
                    if !experienceVM.milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Upcoming Milestones")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(Array(experienceVM.milestones.prefix(3).enumerated()), id: \.element.id) { index, milestone in
                                ModernCard(padding: 16) {
                                    MilestoneCardRow(milestone: milestone) {
                                        experienceVM.toggleMilestone(milestone)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .fadeInUp(delay: Double(index) * 0.1)
                            }
                        }
                    }
                    
                    // Reminders
                    if !experienceVM.reminders.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminders")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(Array(experienceVM.reminders.prefix(3).enumerated()), id: \.element.id) { index, reminder in
                                ModernCard(padding: 16) {
                                    ReminderCardRow(reminder: reminder)
                                }
                                .padding(.horizontal, 24)
                                .fadeInUp(delay: Double(index) * 0.1)
                            }
                        }
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Home")
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
        .sheet(isPresented: $showAddGoal) {
            AddGoalSheet(
                title: $newGoalTitle,
                details: $newGoalDetails,
                priority: $newGoalPriority,
                dueDate: $newGoalDate,
                onSubmit: {
                    handleGoalSubmit()
                    showAddGoal = false
                }
            )
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(text: $newNoteText, onSubmit: {
                handleNoteSubmit()
                showAddNote = false
            })
        }
    }
    
    private func handleGoalSubmit() {
        guard !newGoalTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        experienceVM.addGoal(
            title: newGoalTitle,
            description: newGoalDetails,
            dueDate: newGoalDate,
            priority: newGoalPriority
        )
        newGoalTitle = ""
        newGoalDetails = ""
        newGoalPriority = "Medium"
        newGoalDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    private func handleNoteSubmit() {
        guard !newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        experienceVM.addNote(content: newNoteText)
        newNoteText = ""
    }
}

private struct MilestoneCardRow: View {
    let milestone: Milestone
    let toggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                toggle()
                HapticManager.shared.trigger(milestone.completed ? .light : .medium)
            } label: {
                Image(systemName: milestone.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(milestone.completed ? AppColors.duolingoGreen : AppColors.primaryOrange)
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
                        .foregroundColor(.secondary)
                    Text(milestone.dueDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

private struct ReminderCardRow: View {
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
                        .foregroundColor(.secondary)
                    Text(reminder.scheduledDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

private struct AddGoalSheet: View {
    @Binding var title: String
    @Binding var details: String
    @Binding var priority: String
    @Binding var dueDate: Date
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let priorities = ["High", "Medium", "Low"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        ModernTextField(
                            title: "Title",
                            text: $title,
                            placeholder: "Enter goal title",
                            icon: "target"
                        )
                        
                        ModernTextField(
                            title: "Description",
                            text: $details,
                            placeholder: "Enter goal description",
                            icon: "note.text"
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Picker("Priority", selection: $priority) {
                                ForEach(priorities, id: \.self) { value in
                                    Text(value).tag(value)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    PlayfulButton(
                        title: "Add",
                        icon: "plus.circle.fill",
                        gradient: AppColors.primaryGradient,
                        disabled: title.trimmingCharacters(in: .whitespaces).isEmpty
                    ) {
                        onSubmit()
                        dismiss()
                    }
                    .frame(width: 80)
                }
            }
        }
    }
}

private struct AddNoteSheet: View {
    @Binding var text: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ModernTextField(
                        title: "",
                        text: $text,
                        placeholder: "Write your note here...",
                        icon: "square.and.pencil"
                    )
                    .padding(24)
                    
                    Spacer()
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    PlayfulButton(
                        title: "Save",
                        icon: "checkmark.circle.fill",
                        gradient: AppColors.successGradient,
                        disabled: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        onSubmit()
                        dismiss()
                    }
                    .frame(width: 80)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeExperienceView()
            .environmentObject(ExperienceViewModel())
            .environmentObject(BusinessPlanStore())
    }
}
