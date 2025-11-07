import SwiftUI

struct PlannerNotesView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @ObservedObject var timelineVM: IslandTimelineViewModel
    
    @State private var activeTab = 0
    @State private var showNewNote = false
    @State private var showNewReminder = false
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var selectedIsland: Island?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plan & Notes")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        TabButton(
                            title: "Notes",
                            icon: "note.text",
                            isActive: activeTab == 0
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                activeTab = 0
                            }
                        }
                        
                        TabButton(
                            title: "Reminders",
                            icon: "bell.badge",
                            isActive: activeTab == 1
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                activeTab = 1
                            }
                        }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.9), AppColors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                
                // Content
                ZStack {
                    // Notes Tab
                    if activeTab == 0 {
                        OldNotesTabView(
                            timelineVM: timelineVM,
                            showNewNote: $showNewNote
                        )
                        .transition(.opacity)
                    }
                    
                    // Reminders Tab
                    if activeTab == 1 {
                        RemindersTabView(
                            timelineVM: timelineVM,
                            showNewReminder: $showNewReminder
                        )
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showNewNote) {
            NewNoteSheet(timelineVM: timelineVM, isPresented: $showNewNote)
        }
        .sheet(isPresented: $showNewReminder) {
            ReminderComposerView(isPresented: $showNewReminder, defaultDate: Date()) { title, note, date, addToCalendar in
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

private struct TabButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(isActive ? .white : .white.opacity(0.6))
            .background(isActive ? Color.white.opacity(0.2) : Color.clear)
            .cornerRadius(8)
        }
    }
}

private struct OldNotesTabView: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @Binding var showNewNote: Bool
    
    var allNotes: [(islandId: String, notes: [ProgressNote])] {
        timelineVM.islands.compactMap { island in
            let notes = timelineVM.getNotesFor(islandId: island.id)
            return notes.isEmpty ? nil : (island.id, notes)
        }
    }
    
    var body: some View {
        notesContent
    }
    
    private var notesContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Add button
                Button(action: { showNewNote = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Note")
                            .font(.headline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                if allNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.primary.opacity(0.4))
                        Text("No notes yet")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Create your first note to track ideas and progress")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    notesListContent
                }
            }
        }
    }
    
    private var notesListContent: some View {
        VStack(spacing: 16) {
            ForEach(allNotes, id: \.islandId) { islandId, notes in
                if let island = timelineVM.islands.first(where: { $0.id == islandId }) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(island.title)
                            .font(.headline.bold())
                            .foregroundColor(AppColors.primary)
                        
                        VStack(spacing: 8) {
                            ForEach(notes, id: \.id) { note in
                                ModernCard(
                                    gradient: LinearGradient(
                                        colors: [
                                            AppColors.primary.opacity(0.1),
                                            AppColors.accent.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    borderColor: AppColors.primary.opacity(0.2),
                                    padding: 12
                                ) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(note.content)
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Text(formatDate(note.createdAt))
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        timelineVM.deleteNote(id: note.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .padding(.vertical, 24)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct RemindersTabView: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @Binding var showNewReminder: Bool
    
    var activeReminders: [AppReminder] {
        timelineVM.reminders
            .filter { !$0.isCompleted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    var completedReminders: [AppReminder] {
        timelineVM.reminders
            .filter { $0.isCompleted }
            .sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Add button
                Button(action: { showNewReminder = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Reminder")
                            .font(.headline)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: AppColors.primary.opacity(0.3), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                if activeReminders.isEmpty && completedReminders.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.primary.opacity(0.4))
                        Text("No reminders")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        Text("Create reminders to stay on track")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                } else {
                    VStack(spacing: 24) {
                        // Active reminders
                        if !activeReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Upcoming")
                                    .font(.headline.bold())
                                    .foregroundColor(AppColors.primaryOrange)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 8) {
                                    ForEach(activeReminders, id: \.id) { reminder in
                                        ReminderRow(
                                            reminder: reminder,
                                            onComplete: {
                                                timelineVM.completeReminder(id: reminder.id)
                                            },
                                            onDelete: {
                                                timelineVM.deleteReminder(id: reminder.id)
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        // Completed reminders
                        if !completedReminders.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Completed")
                                    .font(.headline.bold())
                                    .foregroundColor(AppColors.duolingoGreen)
                                    .padding(.horizontal, 24)
                                
                                VStack(spacing: 8) {
                                    ForEach(completedReminders, id: \.id) { reminder in
                                        ReminderRow(
                                            reminder: reminder,
                                            onComplete: { },
                                            onDelete: {
                                                timelineVM.deleteReminder(id: reminder.id)
                                            }
                                        )
                                        .opacity(0.6)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 24)
                }
            }
        }
    }
}

private struct ReminderRow: View {
    let reminder: AppReminder
    let onComplete: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ModernCard(
            gradient: LinearGradient(
                colors: [
                    reminder.isCompleted
                        ? AppColors.duolingoGreen.opacity(0.08)
                        : AppColors.primary.opacity(0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            borderColor: reminder.isCompleted
                ? AppColors.duolingoGreen.opacity(0.2)
                : AppColors.primary.opacity(0.2),
            padding: 16
        ) {
            HStack(spacing: 16) {
                Button(action: onComplete) {
                    Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(
                            reminder.isCompleted
                                ? AppColors.duolingoGreen
                                : AppColors.primary
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .strikethrough(reminder.isCompleted)
                    
                    if !reminder.message.isEmpty {
                        Text(reminder.message)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(formatDate(reminder.scheduledDate))
                            .font(.caption2)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct NewNoteSheet: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @Binding var isPresented: Bool
    @State private var selectedIslandId: String = ""
    @State private var noteContent = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                Form {
                    Section("Island") {
                        Picker("Select Island", selection: $selectedIslandId) {
                            ForEach(timelineVM.islands, id: \.id) { island in
                                Text(island.title).tag(island.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Section("Note") {
                        TextEditor(text: $noteContent)
                            .frame(height: 150)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !selectedIslandId.isEmpty && !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            timelineVM.addNote(
                                content: noteContent,
                                islandId: selectedIslandId
                            )
                            isPresented = false
                        }
                    }
                    .disabled(selectedIslandId.isEmpty || noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if selectedIslandId.isEmpty && !timelineVM.islands.isEmpty {
                    selectedIslandId = timelineVM.islands[0].id
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PlannerNotesView(timelineVM: IslandTimelineViewModel())
            .environmentObject(BusinessPlanStore())
            .environmentObject(ExperienceViewModel())
    }
}
