import SwiftUI
import EventKit

struct IslandDetailView: View {
    let island: Island
    @ObservedObject var viewModel: IslandTimelineViewModel
    let onComplete: () -> Void
    
    @State private var showAddNote = false
    @State private var showAddReminder = false
    @State private var showAISuggestions = false
    @State private var isLoadingAI = false
    @State private var aiSuggestions: String = ""
    @State private var noteText = ""
    @State private var reminderTitle = ""
    @State private var reminderMessage = ""
    @State private var reminderDate = Date()
    @State private var addToCalendar = false
    @Environment(\.dismiss) private var dismiss
    
    private var notes: [ProgressNote] {
        viewModel.getNotesFor(islandId: island.id)
    }
    
    private var islandReminders: [AppReminder] {
        viewModel.reminders.filter { $0.islandId == island.id }
    }
    
    private var completionRate: Double {
        let total = notes.count + islandReminders.count
        guard total > 0 else { return 0 }
        let completed = islandReminders.filter { $0.isCompleted }.count
        return Double(completed + (island.isCompleted ? notes.count : 0)) / Double(total)
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Card
                    ModernCard(
                        gradient: LinearGradient(
                            colors: [island.type.color, island.type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        padding: 24
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text(island.type.icon)
                                    .font(.system(size: 50))
                                
                                Spacer()
                                
                                if island.isCompleted {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.25))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    }
                                }
                            }
                            
                            Text(island.title)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(island.description)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if island.isCompleted, let completedDate = island.completedAt {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Completed \(completedDate.formatted(date: .abbreviated, time: .omitted))")
                                }
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .fadeInUp()
                    
                    // Progress Card
                    if completionRate > 0 {
                        ModernCard(padding: 20) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Progress")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(Int(completionRate * 100))%")
                                        .font(.headline.bold())
                                        .foregroundColor(AppColors.primaryOrange)
                                }
                                
                                ProgressView(value: completionRate)
                                    .tint(AppColors.primaryOrange)
                                    .scaleEffect(y: 2)
                                
                                HStack {
                                    Label("\(notes.count) notes", systemImage: "note.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Label("\(islandReminders.filter { $0.isCompleted }.count)/\(islandReminders.count) reminders", systemImage: "bell.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .fadeInUp(delay: 0.1)
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notes")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddNote = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primaryOrange)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if notes.isEmpty {
                            ModernCard(padding: 40) {
                                VStack(spacing: 12) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No notes yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            ForEach(notes) { note in
                                ModernCard(padding: 16) {
                                    NoteCardRow(note: note) {
                                        viewModel.deleteNote(id: note.id)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .fadeInUp(delay: 0.2)
                    
                    // Reminders Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reminders")
                                .font(.headline)
                            Spacer()
                            Button {
                                showAddReminder = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(AppColors.primaryOrange)
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        if islandReminders.isEmpty {
                            ModernCard(padding: 40) {
                                VStack(spacing: 12) {
                                    Image(systemName: "bell.slash")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No reminders yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            ForEach(islandReminders) { reminder in
                                ModernCard(padding: 16) {
                                    ReminderCardRow(
                                        reminder: reminder,
                                        onToggle: {
                                            viewModel.completeReminder(id: reminder.id)
                                        },
                                        onDelete: {
                                            viewModel.deleteReminder(id: reminder.id)
                                        }
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                    .fadeInUp(delay: 0.3)
                    
                    // AI Suggestions
                    ModernCard(
                        borderColor: AppColors.primaryPink.opacity(0.5),
                        padding: 20
                    ) {
                        Button {
                            fetchAISuggestions()
                        } label: {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.primaryPink.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    if isLoadingAI {
                                        ProgressView()
                                            .tint(AppColors.primaryPink)
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.title3)
                                            .foregroundColor(AppColors.primaryPink)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(isLoadingAI ? "Getting suggestions..." : "Get AI Suggestions")
                                        .font(.headline)
                                    Text("Personalized guidance")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoadingAI)
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp(delay: 0.4)
                    
                    // Complete Button
                    if !island.isCompleted {
                        PlayfulButton(
                            title: "Complete Island",
                            icon: "checkmark.circle.fill",
                            gradient: AppColors.successGradient
                        ) {
                            HapticManager.shared.trigger(.success)
                            onComplete()
                            dismiss()
                        }
                        .padding(.horizontal, 24)
                        .fadeInUp(delay: 0.5)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(island.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteSheet(
                noteText: $noteText,
                onSave: {
                    viewModel.addNote(content: noteText, islandId: island.id)
                    noteText = ""
                    showAddNote = false
                },
                onCancel: {
                    noteText = ""
                    showAddNote = false
                }
            )
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderSheet(
                title: $reminderTitle,
                message: $reminderMessage,
                date: $reminderDate,
                addToCalendar: $addToCalendar,
                onSave: {
                    viewModel.addReminder(
                        title: reminderTitle,
                        message: reminderMessage,
                        scheduledDate: reminderDate,
                        islandId: island.id,
                        addToCalendar: addToCalendar
                    )
                    
                    if addToCalendar {
                        requestCalendarAccess { granted in
                            if granted {
                                addEventToCalendar(
                                    title: reminderTitle,
                                    notes: reminderMessage,
                                    startDate: reminderDate
                                )
                            }
                        }
                    }
                    
                    reminderTitle = ""
                    reminderMessage = ""
                    reminderDate = Date()
                    addToCalendar = false
                    showAddReminder = false
                },
                onCancel: {
                    reminderTitle = ""
                    reminderMessage = ""
                    reminderDate = Date()
                    addToCalendar = false
                    showAddReminder = false
                }
            )
        }
        .sheet(isPresented: $showAISuggestions) {
            AISuggestionsSheet(suggestions: aiSuggestions)
        }
    }
    
    // MARK: - AI Suggestions
    private func fetchAISuggestions() {
        guard !isLoadingAI else { return }
        
        guard !Config.googleAIKey.isEmpty else {
            aiSuggestions = "⚠️ AI is not configured. Please set up your Google AI API key in the app settings to use AI features."
            showAISuggestions = true
            return
        }
        
        isLoadingAI = true
        HapticManager.shared.trigger(.light)
        
        viewModel.askAIAboutProgress(question: "Give me specific actionable suggestions for this island") { response in
            DispatchQueue.main.async {
                self.aiSuggestions = response
                self.isLoadingAI = false
                self.showAISuggestions = true
                HapticManager.shared.trigger(.success)
            }
        }
    }
    
    // MARK: - Calendar Functions
    private func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    private func addEventToCalendar(title: String, notes: String, startDate: Date) {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        
        event.title = title
        event.notes = notes
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(3600)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        let alarm = EKAlarm(relativeOffset: -900)
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            print("Error saving event to calendar: \(error.localizedDescription)")
        }
    }
}

// MARK: - Note Card Row
private struct NoteCardRow: View {
    let note: ProgressNote
    let onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "note.text")
                .foregroundColor(AppColors.primaryOrange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(note.content)
                    .font(.body)
                
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                onDelete()
                HapticManager.shared.trigger(.light)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Reminder Card Row
private struct ReminderCardRow: View {
    let reminder: AppReminder
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                onToggle()
                HapticManager.shared.trigger(.light)
            } label: {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(reminder.isCompleted ? AppColors.duolingoGreen : AppColors.primaryOrange)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .secondary : .primary)
                
                if !reminder.message.isEmpty {
                    Text(reminder.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    Label(reminder.scheduledDate.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if reminder.notifyViaCalendar {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundColor(AppColors.brightBlue)
                    }
                }
            }
            
            Spacer()
            
            Button {
                onDelete()
                HapticManager.shared.trigger(.light)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Add Note Sheet
private struct AddNoteSheet: View {
    @Binding var noteText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ModernTextField(
                        title: "",
                        text: $noteText,
                        placeholder: "Add a note...",
                        icon: "note.text"
                    )
                    .padding(24)
                    
                    Spacer()
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    PlayfulButton(
                        title: "Save",
                        icon: "checkmark.circle.fill",
                        gradient: AppColors.successGradient,
                        disabled: noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        onSave()
                    }
                    .frame(width: 80)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isFocused = true
                }
            }
        }
    }
}

// MARK: - Add Reminder Sheet
private struct AddReminderSheet: View {
    @Binding var title: String
    @Binding var message: String
    @Binding var date: Date
    @Binding var addToCalendar: Bool
    let onSave: () -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool
    
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
                            placeholder: "Enter reminder title",
                            icon: "bell.fill"
                        )
                        
                        ModernTextField(
                            title: "Message",
                            text: $message,
                            placeholder: "Optional message",
                            icon: "note.text"
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            DatePicker("", selection: $date, in: Date()...)
                                .datePickerStyle(.compact)
                        }
                        
                        Toggle("Add to Calendar", isOn: $addToCalendar)
                            .tint(AppColors.primaryOrange)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    PlayfulButton(
                        title: "Save",
                        icon: "checkmark.circle.fill",
                        gradient: AppColors.successGradient,
                        disabled: title.isEmpty
                    ) {
                        onSave()
                    }
                    .frame(width: 80)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    titleFocused = true
                }
            }
        }
    }
}

// MARK: - AI Suggestions Sheet
private struct AISuggestionsSheet: View {
    let suggestions: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    ModernCard(padding: 24) {
                        Text(suggestions)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("AI Suggestions")
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

#Preview {
    NavigationStack {
        IslandDetailView(
            island: Island(
                title: "Launch",
                description: "Launch your business!",
                position: CGPoint(x: 100, y: 100),
                type: .milestone
            ),
            viewModel: IslandTimelineViewModel(),
            onComplete: {}
        )
    }
}
