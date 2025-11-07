import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var contextManager = IntelligentContextManager.shared
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Discover Tab - Landing page with brain dump & idea generation
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: "lightbulb.fill")
                }
                .tag(0)
            
            // 2. Timeline Tab - Progress timeline
            TimelineTabView()
                .tabItem {
                    Label("Timeline", systemImage: "map.fill")
                }
                .tag(1)
            
            // 3. Notes/Reminders Tab - Combined notes & reminders
            NotesTabView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(2)
            
            // 4. AI Assistant Tab - Chat with AI
            AIAssistantTab()
                .tabItem {
                    Label("AI Coach", systemImage: "brain.head.profile")
                }
                .tag(3)
            
            // 5. Settings Tab
            SettingsTabView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(Color(hex: "6366F1"))
    }
}

// AI Assistant as a Tab (cleaner than floating button)
struct AIAssistantTab: View {
    var body: some View {
        NavigationView {
            AIAssistantSheet()
                .navigationBarHidden(true)
        }
    }
}

// MARK: - Timeline Tab View
struct TimelineTabView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var timelineVM: IslandTimelineViewModel
    
    init() {
        _timelineVM = StateObject(wrappedValue: IslandTimelineViewModel())
    }
    
    var body: some View {
        NavigationView {
            TimelineFinal(timelineVM: timelineVM)
        }
    }
}

// MARK: - Notes Tab View
struct NotesTabView: View {
    @StateObject private var notesManager = NotesReminderManager.shared
    @State private var selectedSegment = 0 // 0 = Notes, 1 = Reminders
    @State private var showAddNote = false
    @State private var showAddReminder = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    header
                    
                    // Segment Control
                    segmentControl
                    
                    // Content
                    if selectedSegment == 0 {
                        notesListView
                    } else {
                        remindersListView
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteView()
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderView()
        }
    }
    
    private var header: some View {
        HStack {
            Text("Notes & Reminders")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                if selectedSegment == 0 {
                    showAddNote = true
                } else {
                    showAddReminder = true
                }
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "6366F1"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    private var segmentControl: some View {
        HStack(spacing: 0) {
            SegmentButton(title: "Notes", isSelected: selectedSegment == 0) {
                withAnimation(.spring(response: 0.3)) {
                    selectedSegment = 0
                }
            }
            
            SegmentButton(title: "Reminders", isSelected: selectedSegment == 1) {
                withAnimation(.spring(response: 0.3)) {
                    selectedSegment = 1
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }
    
    private var notesListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if notesManager.notes.isEmpty {
                    emptyState(icon: "note.text", message: "No notes yet")
                } else {
                    ForEach(notesManager.notes) { note in
                        NoteRowView(note: note)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
    
    private var remindersListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if notesManager.reminders.isEmpty {
                    emptyState(icon: "bell", message: "No reminders yet")
                } else {
                    ForEach(notesManager.reminders) { reminder in
                        ReminderRowView(reminder: reminder)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
    
    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Supporting Components

struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

// MARK: - Settings Tab
struct SettingsTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var contextManager = IntelligentContextManager.shared
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                )
                            
                            Text(businessPlanStore.userProfile?.firstName ?? "Entrepreneur")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("\(businessPlanStore.businessIdeas.count) Ideas")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 40)
                        
                        // Stats
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            StatCard(
                                title: "AI Chats",
                                value: "\(contextManager.userInsights.aiInteractionCount)",
                                icon: "brain.head.profile",
                                color: Color(hex: "6366F1")
                            )
                            
                            StatCard(
                                title: "Completion",
                                value: "\(Int(contextManager.userInsights.goalCompletionRate * 100))%",
                                icon: "checkmark.circle.fill",
                                color: Color(hex: "10B981")
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        // Settings Section
                        VStack(spacing: 12) {
                            SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange) {
                                // TODO: Handle notifications settings
                            }
                            SettingsRow(icon: "lock.fill", title: "Privacy", color: .blue) {
                                // TODO: Handle privacy settings
                            }
                            SettingsRow(icon: "info.circle.fill", title: "About", color: .green) {
                                // TODO: Handle about
                            }
                            
                            Button(action: {
                                showingSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)
                                        .frame(width: 32)
                                    
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    authVM.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}

struct IdeaCard: View {
    let idea: BusinessIdea
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Text(idea.personalizedNotes)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            ProgressView(value: Double(idea.progress) / 100.0)
                .tint(Color(hex: "6366F1"))
        }
        .padding(16)
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color(hex: "6366F1") : Color.clear)
                .cornerRadius(10)
        }
    }
}

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !note.title.isEmpty {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(note.content)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(3)
            
            Text(note.createdAt, style: .relative)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }
}

struct ReminderRowView: View {
    let reminder: BusinessReminder
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(reminder.isCompleted ? Color(hex: "10B981") : .white.opacity(0.3))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .strikethrough(reminder.isCompleted)
                
                Text(reminder.dueDate, style: .date)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}