import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var experienceVM = ExperienceViewModel()
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeExperienceView()
                    .environmentObject(experienceVM)
                    .environmentObject(businessPlanStore)
                    .tag(0)
                
                BusinessIdeasView()
                    .tag(1)
                
                IslandTimelineView()
                    .environmentObject(businessPlanStore)
                    .tag(2)
                
                ProgressExperienceView()
                    .environmentObject(experienceVM)
                    .tag(3)
                
                AssistantExperienceView()
                    .environmentObject(experienceVM)
                    .environmentObject(businessPlanStore)
                    .tag(4)
                
                NavigationStack {
                    SettingsView()
                        .environmentObject(authVM)
                        .environmentObject(businessPlanStore)
                }
                .tag(5)
            }
            
            VStack {
                Spacer()
                
                // Custom Tab Bar
                HStack(spacing: 0) {
                    ForEach(0..<6, id: \.self) { index in
                        VStack(spacing: 4) {
                            Image(systemName: tabIcon(index))
                                .font(.system(size: 18, weight: .medium))
                            Text(tabLabel(index))
                                .font(Typography.label)
                        }
                        .foregroundColor(selectedTab == index ? AppColors.primary : AppColors.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = index
                            }
                        }
                    }
                }
                .background(AppColors.surface)
                .border(top: AppColors.border, width: 1)
                .ignoresSafeArea(.keyboard)
            }
        }
        .background(AppColors.background)
        .onChange(of: selectedTab) { _, newTab in
            let tabNames = ["Home", "Ideas", "Journey", "Progress", "Assistant", "Settings"]
            if newTab < tabNames.count {
                UserContextManager.shared.trackEvent(.viewOpened, context: [
                    "viewName": tabNames[newTab],
                    "tabIndex": String(newTab)
                ])
            }
        }
        .task(id: authVM.userId) {
            guard let userId = authVM.userId else { return }
            businessPlanStore.attachUser(userId: userId)
            experienceVM.attach(store: businessPlanStore, userId: userId)
            
            if let profile = businessPlanStore.userProfile {
                await UserContextManager.shared.initializeContext(userId: userId, profile: profile)
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingFlow()
        }
    }
    
    private func tabIcon(_ index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "lightbulb.fill"
        case 2: return "map.fill"
        case 3: return "chart.bar.fill"
        case 4: return "sparkles"
        default: return "gear.fill"
        }
    }
    
    private func tabLabel(_ index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "Ideas"
        case 2: return "Journey"
        case 3: return "Progress"
        case 4: return "AI"
        default: return "Settings"
        }
    }
    
    private func checkOnboardingStatus() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            showingOnboarding = true
        }
    }
}

extension View {
    func border(top: Color, width: CGFloat = 1) -> some View {
        overlay(alignment: .top) {
            VStack {
                top.frame(height: width)
                Spacer()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(BusinessPlanStore())
}
