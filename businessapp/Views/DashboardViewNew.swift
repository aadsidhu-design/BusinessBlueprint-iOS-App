import SwiftUI
import EventKit

struct DashboardViewNew: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showAddBusinessPlan = false
    @State private var showAddReminder = false
    @State private var showAddNote = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        headerSection
                        
                        // Main Content
                        if businessPlanStore.businessIdeas.isEmpty {
                            emptyState
                        } else {
                            content
                        }
                        
                        // Quick Actions Section
                        quickActionsSection
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddBusinessPlan) {
            BusinessPlanWizard(isPresented: $showAddBusinessPlan)
        }
        .sheet(isPresented: $showAddReminder) {
            AddReminderViewNew(isPresented: $showAddReminder)
        }
        .sheet(isPresented: $showAddNote) {
            AddNoteViewNew(isPresented: $showAddNote)
        }
        .onAppear {
            viewModel.selectedBusinessIdea = businessPlanStore.selectedBusinessIdea
            if let idea = viewModel.selectedBusinessIdea {
                viewModel.bootstrapDemoData(for: idea)
            }
        }
    }
    
    var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title2)
                            .foregroundColor(mintGreen)
                        Text("Business Blueprint")
                            .font(.title2.bold())
                            .foregroundColor(.black)
                    }
                }
                
                Spacer()
                
                // Add Business Plan Button in Header
                Button {
                    showAddBusinessPlan = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(mintGreen)
                        .clipShape(Circle())
                        .shadow(color: mintGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            // Time Period Selector
            HStack(spacing: 20) {
                Button("Today") {
                    // Handle today selection
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.black)
                
                Button("Yesterday") {
                    // Handle yesterday selection
                }
                .font(.subheadline)
                .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 20)
    }
    
    var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "lightbulb")
                .font(.system(size: 60))
                .foregroundColor(mintGreen)
            
            Text("No Business Plan Yet")
                .font(.title2.bold())
                .foregroundColor(.black)
            
            Text("Tap the + button to create your first business plan")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    var content: some View {
        VStack(spacing: 24) {
            // Main Progress Card
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(viewModel.completedGoalsCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                        
                        Text("Goals completed")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.completionPercentage) / 100)
                            .stroke(mintGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "target")
                            .font(.title2)
                            .foregroundColor(mintGreen)
                    }
                }
                
                // Stats Row
                HStack(spacing: 24) {
                    StatItem(value: "\(viewModel.dailyGoals.count)", label: "Total goals", color: .pink)
                    StatItem(value: "\(viewModel.milestones.count)", label: "Milestones", color: .orange)
                    StatItem(value: "\(viewModel.completionPercentage)%", label: "Progress", color: mintGreen)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
            .padding(.horizontal, 20)
            
            // Recent Activity
            if !viewModel.upcomingGoals.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recently worked on")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(viewModel.upcomingGoals.prefix(1)) { goal in
                            RecentActivityCard(goal: goal)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            HStack(spacing: 12) {
                // Reminders Card
                QuickActionCard(
                    title: "Reminders",
                    subtitle: "Calendar integration",
                    icon: "bell.fill",
                    color: .orange
                ) {
                    showAddReminder = true
                }
                
                // Notes Card
                QuickActionCard(
                    title: "Notes",
                    subtitle: "Brain dump ideas",
                    icon: "note.text",
                    color: .blue
                ) {
                    showAddNote = true
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 120)
    }
    

    
    private var mintGreen: Color {
        Color(red: 0.0, green: 0.8, blue: 0.6)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.black)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct RecentActivityCard: View {
    let goal: DailyGoal
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.gray)
                )
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.black)
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundColor(.pink)
                        Text("Priority: \(goal.priority)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text(goal.dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.6))
                        Text(goal.completed ? "Done" : "Pending")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            Text(goal.dueDate.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Add Business Plan View
struct AddBusinessPlanView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @Binding var isPresented: Bool
    @State private var businessName = ""
    @State private var businessDescription = ""
    @State private var industry = "Technology"
    @State private var targetMarket = ""
    
    private let industries = ["Technology", "Healthcare", "Finance", "Education", "Retail", "Food & Beverage", "Real Estate", "Manufacturing", "Other"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Business Name")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Enter your business name", text: $businessName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Describe your business idea", text: $businessDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Industry")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            Picker("Industry", selection: $industry) {
                                ForEach(industries, id: \.self) { industry in
                                    Text(industry).tag(industry)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Market")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Who are your customers?", text: $targetMarket)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button {
                            createBusinessPlan()
                        } label: {
                            Text("Create Business Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.0, green: 0.8, blue: 0.6))
                                .cornerRadius(12)
                        }
                        .disabled(businessName.isEmpty || businessDescription.isEmpty)
                        .opacity(businessName.isEmpty || businessDescription.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Business Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func createBusinessPlan() {
        // Create new business idea and add to store
        let newIdea = BusinessIdea(
            id: UUID().uuidString,
            title: businessName,
            description: businessDescription,
            category: industry,
            difficulty: "Medium",
            estimatedRevenue: "TBD",
            timeToLaunch: "6-12 months",
            requiredSkills: [],
            startupCost: "TBD",
            profitMargin: "TBD",
            marketDemand: "Medium",
            competition: "Medium",
            createdAt: Date(),
            userId: "",
            personalizedNotes: "",
            saved: true,
            progress: 0
        )
        
        // Add to business plan store
        businessPlanStore.updateIdea(newIdea)
        businessPlanStore.selectIdea(newIdea)
        
        isPresented = false
    }
}

// MARK: - Add Reminder View
struct AddReminderViewNew: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date()
    @State private var reminderTime = Date()
    @State private var addToCalendar = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reminder Title")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("What do you need to remember?", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Additional details", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            DatePicker("", selection: $reminderTime)
                                .datePickerStyle(.graphical)
                        }
                        
                        HStack {
                            Toggle("Add to Calendar", isOn: $addToCalendar)
                                .tint(Color(red: 0.0, green: 0.8, blue: 0.6))
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        
                        Button {
                            createReminder()
                        } label: {
                            Text("Create Reminder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func createReminder() {
        if addToCalendar {
            addToAppleCalendar()
        }
        // Save reminder locally as well
        isPresented = false
    }
    
    private func addToAppleCalendar() {
        let eventStore = EKEventStore()
        
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                handleCalendarAccess(granted: granted, error: error)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                handleCalendarAccess(granted: granted, error: error)
            }
        }
    }
    
    private func handleCalendarAccess(granted: Bool, error: Error?) {
        if granted && error == nil {
            let eventStore = EKEventStore()
            let event = EKEvent(eventStore: eventStore)
            event.title = title
            event.notes = notes
            event.startDate = reminderTime
            event.endDate = reminderTime.addingTimeInterval(3600) // 1 hour duration
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(event, span: .thisEvent)
            } catch {
                print("Failed to save event: \(error)")
            }
        }
    }
}

// MARK: - Add Note View
struct AddNoteViewNew: View {
    @Binding var isPresented: Bool
    @State private var title = ""
    @State private var content = ""
    @State private var category = "Ideas"
    
    private let categories = ["Ideas", "Research", "Goals", "Insights", "Other"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note Title")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Give your note a title", text: $title)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Content")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.black)
                            
                            TextField("Brain dump your thoughts here...", text: $content, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(5...10)
                        }
                        
                        Button {
                            createNote()
                        } label: {
                            Text("Save Note")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(title.isEmpty || content.isEmpty)
                        .opacity(title.isEmpty || content.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func createNote() {
        // Save note locally
        // You can implement note storage here
        isPresented = false
    }
}

#Preview {
    DashboardViewNew()
        .environmentObject(BusinessPlanStore())
}