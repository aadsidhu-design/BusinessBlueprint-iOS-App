//
//  ContentView.swift
//  businessapp
//
//  Created by Aadjot Singh Sidhu on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if authVM.isLoggedIn {
                MainTabViewNew()
                    .onAppear {
                        checkOnboardingStatus()
                    }
            } else {
                AuthViewNew(viewModel: authVM)
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    private func checkOnboardingStatus() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(BusinessPlanStore())
}
