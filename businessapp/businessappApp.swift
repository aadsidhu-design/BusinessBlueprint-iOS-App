//
//  businessappApp.swift
//  businessapp
//
//  Created by Aadjot Singh Sidhu on 11/4/25.
//

import SwiftUI

@main
struct businessappApp: App {
    @StateObject private var authVM: AuthViewModel
    @StateObject private var businessPlanStore = BusinessPlanStore()
    
    init() {
        let authViewModel = AuthViewModel()
        _authVM = StateObject(wrappedValue: authViewModel)
        authViewModel.checkLoginStatus()
    }
    
    var body: some Scene {
        WindowGroup {
            if authVM.isLoggedIn {
                RootView()
                    .environmentObject(authVM)
                    .environmentObject(businessPlanStore)
            } else {
                LaunchView()
                    .environmentObject(authVM)
                    .environmentObject(businessPlanStore)
            }
        }
    }
}
