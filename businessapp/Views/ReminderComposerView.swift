import SwiftUI

struct ReminderComposerView: View {
    @Binding var isPresented: Bool
    let defaultDate: Date
    let onSave: (String, String, Date, Bool) -> Void
    @State private var title = ""
    @State private var note = ""
    @State private var dueDate: Date
    @State private var addToCalendar = true
    
    init(isPresented: Binding<Bool>, defaultDate: Date, onSave: @escaping (String, String, Date, Bool) -> Void) {
        self._isPresented = isPresented
        self.defaultDate = defaultDate
        self.onSave = onSave
        self._dueDate = State(initialValue: defaultDate)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Title", text: $title)
                    TextField("Note", text: $note, axis: .vertical)
                }
                
                Section("Schedule") {
                    DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.graphical)
                }
                
                Section("Calendar") {
                    Toggle("Add to Apple Calendar", isOn: $addToCalendar)
                        .tint(AppColors.primary)
                    Text("We'll request calendar permission if needed.")
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("New Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title, note, dueDate, addToCalendar)
                        isPresented = false
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ReminderComposerView(isPresented: .constant(true), defaultDate: Date()) { _, _, _, _ in }
}
