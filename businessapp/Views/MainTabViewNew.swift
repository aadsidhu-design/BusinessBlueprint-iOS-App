import SwiftUI
import Combine

struct MainTabViewNew: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var experienceVM = ExperienceViewModel()
    @StateObject private var timelineVM = IslandTimelineViewModel()
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @State private var hasLinkedTimeline = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TimelineFinal(timelineVM: timelineVM)
            }
            .tabItem {
                Label("Journey", systemImage: "map.fill")
            }
            .tag(0)
            
            NavigationStack {
                PlannerNotesView(timelineVM: timelineVM)
            }
            .tabItem {
                Label("Planner", systemImage: "doc.text.magnifyingglass")
            }
            .tag(1)
            
            NavigationStack {
                CoachHubView(timelineVM: timelineVM)
            }
            .tabItem {
                Label("Coach", systemImage: "sparkles")
            }
            .tag(2)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .environmentObject(experienceVM)
        .tint(AppColors.primary)
        .task(id: authVM.userId) {
            guard let userId = authVM.userId else { return }
            businessPlanStore.attachUser(userId: userId)
            experienceVM.attach(store: businessPlanStore, userId: userId)
            
            if !hasLinkedTimeline {
                timelineVM.connectToStore(businessPlanStore)
                hasLinkedTimeline = true
            }
            
            if let profile = businessPlanStore.userProfile {
                await UserContextManager.shared.initializeContext(userId: userId, profile: profile)
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToPlannerTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToJourneyTab)) { _ in
            selectedTab = 0
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingFlow()
        }
    }
    
    private func checkOnboardingStatus() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showingOnboarding = true
        }
    }
}
