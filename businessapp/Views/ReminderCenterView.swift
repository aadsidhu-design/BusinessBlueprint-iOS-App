import SwiftUI

struct ReminderCenterView: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @State private var showComposer = false
    
    private var activeReminders: [AppReminder] {
        timelineVM.reminders.filter { !$0.isCompleted }.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private var completedReminders: [AppReminder] {
        timelineVM.reminders.filter { $0.isCompleted }.sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    var body: some View {
        ZStack {
            AppColors.groupedBackground
                .ignoresSafeArea()
            
            if timelineVM.reminders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 48))
                        .foregroundColor(AppColors.primaryOrange)
                    Text("No reminders yet")
                        .font(.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Create reminders to keep your business journey on track.")
                        .font(.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    PlayfulButton(title: "Create Reminder", icon: "plus", gradient: AppColors.blueGradient) {
                        showComposer = true
                    }
                    .padding(.top, 12)
                }
                .padding()
            } else {
                List {
                    if !activeReminders.isEmpty {
                        Section("Upcoming") {
                            ForEach(activeReminders) { reminder in
                                ReminderRow(reminder: reminder) {
                                    timelineVM.completeReminder(id: reminder.id)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        timelineVM.deleteReminder(id: reminder.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    
                    if !completedReminders.isEmpty {
                        Section("Completed") {
                            ForEach(completedReminders) { reminder in
                                ReminderRow(reminder: reminder, isHistoric: true) {
                                    timelineVM.completeReminder(id: reminder.id)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        timelineVM.deleteReminder(id: reminder.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showComposer = true
                    HapticManager.shared.trigger(.light)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .sheet(isPresented: $showComposer) {
            ReminderComposerView(isPresented: $showComposer, defaultDate: Date().addingTimeInterval(3600)) { title, note, date, addToCalendar in
                timelineVM.addReminder(
                    title: title,
                    message: note,
                    scheduledDate: date,
                    addToCalendar: addToCalendar
                )
            }
        }
    }
}

private struct ReminderRow: View {
    let reminder: AppReminder
    var isHistoric: Bool = false
    let toggle: () -> Void
    
    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "bell.badge.fill")
                    .font(.title3)
                    .foregroundColor(reminder.isCompleted ? AppColors.duolingoGreen : AppColors.primaryOrange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .strikethrough(reminder.isCompleted)
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                    Text(reminder.scheduledDate, format: .dateTime.weekday().day().month().hour().minute())
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
            .opacity(isHistoric ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ReminderCenterView(timelineVM: IslandTimelineViewModel())
    }
}
