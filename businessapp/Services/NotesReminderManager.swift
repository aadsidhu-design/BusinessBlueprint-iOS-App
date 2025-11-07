import Foundation
import Combine
import EventKit
import UserNotifications
import FirebaseFirestore
import FirebaseCrashlytics

// MARK: - Helper Extensions

extension Dictionary {
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        let pairs = try map { (try transform($0), $1) }
        return Dictionary<T, Value>(uniqueKeysWithValues: pairs)
    }
}

// MARK: - Note Model
struct Note: Identifiable, Codable {
    let id: String
    var content: String
    var title: String
    var category: NoteCategory
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var businessIdeaId: String?
    var isStarred: Bool
    var attachments: [NoteAttachment]
    
    init(
        content: String,
        title: String = "",
        category: NoteCategory = .general,
        tags: [String] = [],
        businessIdeaId: String? = nil
    ) {
        self.id = UUID().uuidString
        self.content = content
        self.title = title.isEmpty ? String(content.prefix(50)) : title
        self.category = category
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.businessIdeaId = businessIdeaId
        self.isStarred = false
        self.attachments = []
    }
}

enum NoteCategory: String, CaseIterable, Codable {
    case general = "General"
    case businessIdea = "Business Ideas"
    case planning = "Planning"
    case research = "Research"
    case meetings = "Meetings"
    case insights = "Insights"
    case todos = "To-Do"
    case inspiration = "Inspiration"
    
    var icon: String {
        switch self {
        case .general: return "doc.text"
        case .businessIdea: return "lightbulb"
        case .planning: return "calendar"
        case .research: return "magnifyingglass"
        case .meetings: return "person.2"
        case .insights: return "brain.head.profile"
        case .todos: return "checklist"
        case .inspiration: return "star"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "6366F1"
        case .businessIdea: return "F59E0B"
        case .planning: return "10B981"
        case .research: return "8B5CF6"
        case .meetings: return "EF4444"
        case .insights: return "06B6D4"
        case .todos: return "F97316"
        case .inspiration: return "EC4899"
        }
    }
}

struct NoteAttachment: Codable, Identifiable {
    let id: String
    let type: AttachmentType
    let name: String
    let url: String?
    let data: Data?
    
    enum AttachmentType: String, Codable {
        case image, document, link, voice
    }
}

// MARK: - Reminder Model
struct BusinessReminder: Identifiable, Codable {
    let id: String
    var title: String
    var description: String
    var dueDate: Date
    var reminderType: ReminderType
    var priority: Priority
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var businessIdeaId: String?
    var recurrence: RecurrenceRule?
    var notificationId: String?
    
    init(
        title: String,
        description: String = "",
        dueDate: Date,
        reminderType: ReminderType = .custom,
        priority: Priority = .medium,
        businessIdeaId: String? = nil,
        recurrence: RecurrenceRule? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.dueDate = dueDate
        self.reminderType = reminderType
        self.priority = priority
        self.isCompleted = false
        self.completedAt = nil
        self.createdAt = Date()
        self.businessIdeaId = businessIdeaId
        self.recurrence = recurrence
        self.notificationId = nil
    }
}

enum RecurrenceRule: String, CaseIterable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var interval: DateComponents {
        switch self {
        case .daily: return DateComponents(day: 1)
        case .weekly: return DateComponents(weekOfYear: 1)
        case .monthly: return DateComponents(month: 1)
        case .yearly: return DateComponents(year: 1)
        }
    }
}

// MARK: - Notes & Reminder Manager
@MainActor
class NotesReminderManager: ObservableObject {
    static let shared = NotesReminderManager()
    
    @Published var notes: [Note] = []
    @Published var reminders: [BusinessReminder] = []
    @Published var searchText = ""
    @Published var selectedCategory: NoteCategory?
    @Published var isLoading = false
    
    private let firestore = Firestore.firestore()
    private let eventStore = EKEventStore()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var currentUserId: String?
    
    // MARK: - Computed Properties
    
    var filteredNotes: [Note] {
        var filtered = notes
        
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { note in
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var upcomingReminders: [BusinessReminder] {
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        
        return reminders
            .filter { !$0.isCompleted && $0.dueDate >= now && $0.dueDate <= nextWeek }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    var overdueReminders: [BusinessReminder] {
        let now = Date()
        return reminders
            .filter { !$0.isCompleted && $0.dueDate < now }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private init() {
        requestPermissions()
    }
    
    // MARK: - Permissions
    
    private func requestPermissions() {
        // Request calendar access
        eventStore.requestFullAccessToEvents { granted, error in
            if let error = error {
                print("Calendar permission error: \(error)")
            }
        }
        
        // Request notification permissions
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // MARK: - User Management
    
    func setUserId(_ userId: String) {
        currentUserId = userId
        Task {
            await loadUserData()
        }
    }
    
    // MARK: - Notes Management
    
    func createNote(
        content: String,
        title: String = "",
        category: NoteCategory = .general,
        tags: [String] = [],
        businessIdeaId: String? = nil
    ) {
        let note = Note(
            content: content,
            title: title,
            category: category,
            tags: tags,
            businessIdeaId: businessIdeaId
        )
        
        notes.insert(note, at: 0)
        
        // Record in context
        IntelligentContextManager.shared.recordNoteCreated(
            content: content,
            category: category.rawValue
        )
        
        // Save to Firebase
        Task {
            await saveNote(note)
        }
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            var updatedNote = note
            updatedNote.updatedAt = Date()
            notes[index] = updatedNote
            
            Task {
                await saveNote(updatedNote)
            }
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        
        Task {
            await removeNote(note.id)
        }
    }
    
    func toggleNoteStar(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isStarred.toggle()
            Task {
                await saveNote(notes[index])
            }
        }
    }
    
    // MARK: - Reminders Management
    
    func createReminder(
        title: String,
        description: String = "",
        dueDate: Date,
        reminderType: ReminderType = .custom,
        priority: Priority = .medium,
        businessIdeaId: String? = nil,
        recurrence: RecurrenceRule? = nil,
        addToCalendar: Bool = false,
        enableNotifications: Bool = true
    ) async {
        let reminder = BusinessReminder(
            title: title,
            description: description,
            dueDate: dueDate,
            reminderType: reminderType,
            priority: priority,
            businessIdeaId: businessIdeaId,
            recurrence: recurrence
        )
        
        reminders.append(reminder)
        
        // Record in context
        IntelligentContextManager.shared.recordReminderSet(
            title: title,
            date: dueDate,
            type: reminderType
        )
        
        // Schedule local notification
        if enableNotifications {
            await scheduleNotification(for: reminder)
        }
        
        // Add to calendar if requested
        if addToCalendar {
            let success = await addReminderToCalendar(reminder)
            if success {
                print("✅ Reminder added to calendar: \(reminder.title)")
            }
        }
        
        // Save to Firebase
        await saveReminder(reminder)
    }
    
    func updateReminder(_ reminder: BusinessReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            
            Task {
                await saveReminder(reminder)
                
                // Update notification if it exists
                if let notificationId = reminder.notificationId {
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
                    if !reminder.isCompleted {
                        await scheduleNotification(for: reminder)
                    }
                }
            }
        }
    }
    
    func completeReminder(_ reminder: BusinessReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted = true
            reminders[index].completedAt = Date()
            
            // Record completion in context
            IntelligentContextManager.shared.recordAction(
                .milestoneCompleted(title: reminder.title, progress: 1.0),
                businessIdeaId: reminder.businessIdeaId
            )
            
            // Remove notification
            if let notificationId = reminder.notificationId {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
            }
            
            // Create next recurrence if applicable
            if let recurrence = reminder.recurrence {
                let nextDate = Calendar.current.date(byAdding: recurrence.interval, to: reminder.dueDate)
                if let nextDate = nextDate {
                    Task {
                        await createReminder(
                            title: reminder.title,
                            description: reminder.description,
                            dueDate: nextDate,
                            reminderType: reminder.reminderType,
                            priority: reminder.priority,
                            businessIdeaId: reminder.businessIdeaId,
                            recurrence: recurrence
                        )
                    }
                }
            }
            
            Task {
                await saveReminder(reminders[index])
            }
        }
    }
    
    func deleteReminder(_ reminder: BusinessReminder) {
        reminders.removeAll { $0.id == reminder.id }
        
        // Remove notification
        if let notificationId = reminder.notificationId {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        Task {
            await removeReminder(reminder.id)
        }
    }
    
    // MARK: - Calendar Integration
    
    func exportToCalendar(notes: [Note] = [], reminders: [BusinessReminder] = []) async -> Bool {
        let exportedItems = notes.map { $0.title } + reminders.map { $0.title }
        
        // Record export action
        IntelligentContextManager.shared.recordAction(
            .exportedToCalendar(items: exportedItems)
        )
        
        var successCount = 0
        
        // Export notes as all-day events
        for note in notes {
            if await addNoteToCalendar(note) {
                successCount += 1
            }
        }
        
        // Export reminders as timed events
        for reminder in reminders {
            if await addReminderToCalendar(reminder) {
                successCount += 1
            }
        }
        
        return successCount > 0
    }
    
    private func addNoteToCalendar(_ note: Note) async -> Bool {
        let event = EKEvent(eventStore: eventStore)
        event.title = note.title.isEmpty ? "Note: \(String(note.content.prefix(30)))" : note.title
        event.notes = note.content
        event.startDate = note.createdAt
        event.endDate = note.createdAt
        event.isAllDay = true
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save note to calendar: \(error)")
            return false
        }
    }
    
    private func addReminderToCalendar(_ reminder: BusinessReminder) async -> Bool {
        let event = EKEvent(eventStore: eventStore)
        event.title = reminder.title
        event.notes = reminder.description
        event.startDate = reminder.dueDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: reminder.dueDate) ?? reminder.dueDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        // Add alarm 15 minutes before
        let alarm = EKAlarm(relativeOffset: -15 * 60) // 15 minutes before
        event.addAlarm(alarm)
        
        do {
            try eventStore.save(event, span: .thisEvent)
            return true
        } catch {
            print("Failed to save reminder to calendar: \(error)")
            return false
        }
    }
    
    // MARK: - Notifications
    
    private func scheduleNotification(for reminder: BusinessReminder) async {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.description.isEmpty ? "Reminder due" : reminder.description
        content.sound = .default
        content.badge = 1
        
        // Add category based on priority
        content.categoryIdentifier = "REMINDER_\(reminder.priority.rawValue.uppercased())"
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let notificationId = "reminder_\(reminder.id)"
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            
            // Update reminder with notification ID
            if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[index].notificationId = notificationId
            }
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }
    
    // MARK: - Smart Suggestions
    
    func generateSmartSuggestions(for businessIdeaId: String) -> [String] {
        let relatedNotes = notes.filter { $0.businessIdeaId == businessIdeaId }
        let relatedReminders = reminders.filter { $0.businessIdeaId == businessIdeaId }
        
        var suggestions: [String] = []
        
        // Suggest based on note patterns
        let commonWords = extractCommonWords(from: relatedNotes.map { $0.content }.joined(separator: " "))
        for word in commonWords.prefix(3) {
            suggestions.append("Research more about \(word)")
            suggestions.append("Create action plan for \(word)")
        }
        
        // Suggest based on reminder patterns
        if relatedReminders.isEmpty {
            suggestions.append("Set milestone reminders")
            suggestions.append("Schedule weekly progress check")
        }
        
        // Suggest based on missing categories
        let usedCategories = Set(relatedNotes.map { $0.category })
        let missingCategories = Set(NoteCategory.allCases).subtracting(usedCategories)
        
        for category in missingCategories.prefix(2) {
            suggestions.append("Add \(category.rawValue.lowercased()) notes")
        }
        
        return Array(suggestions.prefix(5))
    }
    
    private func extractCommonWords(from text: String) -> [String] {
        let words = text.lowercased()
            .components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count > 4 }
        
        let wordCounts = Dictionary(grouping: words, by: { $0 }).mapValues { $0.count }
        
        return wordCounts
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }
    
    // MARK: - Firebase Operations
    
    private func loadUserData() async {
        guard let userId = currentUserId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load notes
            let notesSnapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection("notes")
                .order(by: "updatedAt", descending: true)
                .getDocuments()
            
            let loadedNotes = notesSnapshot.documents.compactMap { document -> Note? in
                try? document.data(as: Note.self)
            }
            
            // Load reminders
            let remindersSnapshot = try await firestore
                .collection("users")
                .document(userId)
                .collection("reminders")
                .order(by: "dueDate")
                .getDocuments()
            
            let loadedReminders = remindersSnapshot.documents.compactMap { document -> BusinessReminder? in
                try? document.data(as: BusinessReminder.self)
            }
            
            await MainActor.run {
                self.notes = loadedNotes
                self.reminders = loadedReminders
            }
            
        } catch {
            print("Failed to load user data: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func saveNote(_ note: Note) async {
        guard let userId = currentUserId else { return }
        
        do {
            // Organized structure: users/{userId}/notes/{noteId}
            let noteData = [
                "id": note.id,
                "title": note.title,
                "content": note.content,
                "category": note.category.rawValue,
                "businessIdeaId": note.businessIdeaId ?? "",
                "tags": note.tags,
                "isStarred": note.isStarred,
                "createdAt": Timestamp(date: note.createdAt),
                "updatedAt": Timestamp(date: note.updatedAt)
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("notes")
                .document(note.id)
                .setData(noteData)
            
            // Update notes summary for quick access
            await updateNotesSummary()
            
            print("✅ Note saved: \(note.title)")
        } catch {
            print("❌ Failed to save note: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func updateNotesSummary() async {
        guard let userId = currentUserId else { return }
        
        do {
            let categoryBreakdown = Dictionary(grouping: notes, by: { $0.category })
                .mapValues { $0.count }
            
            let summaryData = [
                "totalNotes": notes.count,
                "categoryBreakdown": categoryBreakdown.mapKeys { $0.rawValue },
                "starredCount": notes.filter { $0.isStarred }.count,
                "lastUpdated": Timestamp(date: Date()),
                "version": "1.0"
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("notes")
                .document("_summary")
                .setData(summaryData, merge: true)
        } catch {
            print("❌ Failed to update notes summary: \(error)")
        }
    }
    
    private func saveReminder(_ reminder: BusinessReminder) async {
        guard let userId = currentUserId else { return }
        
        do {
            // Organized structure: users/{userId}/reminders/{reminderId}
            let reminderData = [
                "id": reminder.id,
                "title": reminder.title,
                "description": reminder.description,
                "dueDate": Timestamp(date: reminder.dueDate),
                "priority": reminder.priority.rawValue,
                "reminderType": reminder.reminderType.rawValue,
                "recurrence": reminder.recurrence?.rawValue ?? "",
                "isCompleted": reminder.isCompleted,
                "completedAt": reminder.completedAt.map { Timestamp(date: $0) } ?? NSNull(),
                "businessIdeaId": reminder.businessIdeaId ?? "",
                "createdAt": Timestamp(date: reminder.createdAt),
                "lastModified": Timestamp(date: Date())
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("reminders")
                .document(reminder.id)
                .setData(reminderData)
            
            // Update reminders summary
            await updateRemindersSummary()
            
            print("✅ Reminder saved: \(reminder.title)")
        } catch {
            print("❌ Failed to save reminder: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func updateRemindersSummary() async {
        guard let userId = currentUserId else { return }
        
        do {
            let now = Date()
            let completed = reminders.filter { $0.isCompleted }.count
            let overdue = reminders.filter { $0.dueDate < now && !$0.isCompleted }.count
            let upcoming = reminders.filter { $0.dueDate >= now && !$0.isCompleted }.count
            
            let summaryData = [
                "totalReminders": reminders.count,
                "completedCount": completed,
                "overdueCount": overdue,
                "upcomingCount": upcoming,
                "completionRate": reminders.isEmpty ? 0.0 : Double(completed) / Double(reminders.count),
                "lastUpdated": Timestamp(date: Date()),
                "version": "1.0"
            ] as [String : Any]
            
            try await firestore
                .collection("users")
                .document(userId)
                .collection("reminders")
                .document("_summary")
                .setData(summaryData, merge: true)
        } catch {
            print("❌ Failed to update reminders summary: \(error)")
        }
    }
    
    private func removeNote(_ noteId: String) async {
        guard let userId = currentUserId else { return }
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("notes")
                .document(noteId)
                .delete()
        } catch {
            print("Failed to delete note: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
    
    private func removeReminder(_ reminderId: String) async {
        guard let userId = currentUserId else { return }
        
        do {
            try await firestore
                .collection("users")
                .document(userId)
                .collection("reminders")
                .document(reminderId)
                .delete()
        } catch {
            print("Failed to delete reminder: \(error)")
            Crashlytics.crashlytics().record(error: error)
        }
    }
}