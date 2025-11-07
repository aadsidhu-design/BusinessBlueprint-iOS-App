import SwiftUI

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notesManager = NotesReminderManager.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(3600) // 1 hour from now
    @State private var selectedPriority: Priority = .medium
    @State private var selectedType: ReminderType = .custom
    @State private var addToCalendar = false
    @State private var enableNotifications = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                Form {
                    Section {
                        TextField("Reminder title", text: $title)
                            .foregroundColor(.white)
                        
                        TextField("Description (optional)", text: $description)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    Section {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    Section(header: Text("Priority").foregroundColor(.white.opacity(0.7))) {
                        Picker("Priority", selection: $selectedPriority) {
                            Text("Low").tag(Priority.low)
                            Text("Medium").tag(Priority.medium)
                            Text("High").tag(Priority.high)
                            Text("Critical").tag(Priority.critical)
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    Section(header: Text("Type").foregroundColor(.white.opacity(0.7))) {
                        Picker("Type", selection: $selectedType) {
                            Text("Custom").tag(ReminderType.custom)
                            Text("Meeting").tag(ReminderType.meeting)
                            Text("Deadline").tag(ReminderType.deadline)
                            Text("Follow-up").tag(ReminderType.followup)
                            Text("Milestone").tag(ReminderType.milestone)
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                    
                    Section {
                        Toggle("Add to Calendar", isOn: $addToCalendar)
                            .foregroundColor(.white)
                        
                        Toggle("Enable Notifications", isOn: $enableNotifications)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.white.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReminder()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func saveReminder() {
        Task {
            await notesManager.createReminder(
                title: title,
                description: description,
                dueDate: dueDate,
                reminderType: selectedType,
                priority: selectedPriority,
                addToCalendar: addToCalendar,
                enableNotifications: enableNotifications
            )
            dismiss()
        }
    }
}