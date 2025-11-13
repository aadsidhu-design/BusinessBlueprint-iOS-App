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
            // Dashboard Tab
            NavigationStack {
                DashboardViewNew()
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Home")
            }
            .tag(0)
            
            // Timeline Tab
            NavigationStack {
                IslandTimelineView()
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "map.fill" : "map")
                Text("Timeline")
            }
            .tag(1)
            
            // AI Assistant Tab
            NavigationStack {
                NewAIAssistantView()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "sparkles" : "sparkles")
                Text("AI Assistant")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                Text("Settings")
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
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    
    private func checkOnboardingStatus() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showingOnboarding = true
        }
    }
}
