//
//  businessappApp.swift
//  businessapp
//
//  Created by Aadjot Singh Sidhu on 11/4/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct businessappApp: App {
    @StateObject private var authVM: AuthViewModel
    @StateObject private var businessPlanStore = BusinessPlanStore()
    
    init() {
        // Configure Firebase with minimal services (Auth + Firestore only)
        FirebaseApp.configure()
        
        // Disable App Check to avoid 403 errors
        // We only use Auth and Firestore for this app
        
        let authViewModel = AuthViewModel()
        _authVM = StateObject(wrappedValue: authViewModel)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(businessPlanStore)
                .preferredColorScheme(.dark)
        }
    }
}
