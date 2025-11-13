import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var showingSignOut = false
    @State private var showingDeleteAccount = false
    @State private var showingExportData = false
    @State private var showingOnboarding = false
    @State private var notificationsEnabled = true
    @State private var aiSuggestionsEnabled = true
    @State private var weeklyEmailsEnabled = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean white background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile Card
                        profileCard
                        
                        // Settings Sections
                        preferencesSection
                        dataPrivacySection
                        supportSection
                        accountActionsSection
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .confirmationDialog("Sign Out", isPresented: $showingSignOut) {
            Button("Sign Out", role: .destructive) {
                authVM.signOut()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showingDeleteAccount) {
            Button("Delete Account", role: .destructive) {
                // Handle account deletion
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
    }
    
    private var profileCard: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            // Profile Info
            HStack(spacing: 16) {
                Circle()
                    .fill(mintGreen)
                    .frame(width: 70, height: 70)
                    .overlay {
                        Text(initials)
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(userEmail)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let profile = businessPlanStore.userProfile {
                        HStack(spacing: 8) {
                            Badge("\(profile.skills.count) skills")
                            Badge("\(profile.interests.count) interests")
                        }
                    }
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Push notifications and alerts",
                    action: {
                        Toggle("", isOn: $notificationsEnabled)
                            .tint(mintGreen)
                    }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "sparkles",
                    title: "AI Suggestions",
                    subtitle: "Get AI-powered recommendations",
                    action: {
                        Toggle("", isOn: $aiSuggestionsEnabled)
                            .tint(mintGreen)
                    }
                )
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Weekly Emails",
                    subtitle: "Progress summaries and tips",
                    action: {
                        Toggle("", isOn: $weeklyEmailsEnabled)
                            .tint(mintGreen)
                    }
                )
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data & Privacy")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "arrow.clockwise.circle.fill",
                    title: "Reset Onboarding",
                    subtitle: "Start the welcome tour again",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                    showingOnboarding = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "square.and.arrow.up",
                    title: "Export Data",
                    subtitle: "Download your information",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    showingExportData = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "shield.fill",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    // Open privacy policy
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    subtitle: "Get answers to questions",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    // Open help
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Reach out for assistance",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    // Open contact form
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    icon: "star.fill",
                    title: "Rate App",
                    subtitle: "Share your feedback",
                    action: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                ) {
                    // Request app review
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
    
    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingSignOut = true
            } label: {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .foregroundColor(.red)
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            
            Button {
                showingDeleteAccount = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Delete Account")
                        .font(.headline)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(20)
                .background(Color.red.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    private var mintGreen: Color {
        Color(red: 0.0, green: 0.8, blue: 0.6)
    }
    
    private var initials: String {
        if let profile = businessPlanStore.userProfile {
            let first = profile.firstName.prefix(1)
            let last = profile.lastName.prefix(1)
            return String(first + last).uppercased()
        }
        return "BB"
    }
    
    private var displayName: String {
        if let profile = businessPlanStore.userProfile {
            return "\(profile.firstName) \(profile.lastName)"
        }
        return "Business Builder"
    }
    
    private var userEmail: String {
        authVM.email ?? "user@example.com"
    }
}

struct SettingsRow<ActionView: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> ActionView
    let onTap: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder action: @escaping () -> ActionView,
        onTap: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.6))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                action()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}

struct Badge: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.0, green: 0.8, blue: 0.6).opacity(0.1))
            .cornerRadius(8)
    }
}

struct ExportDataView: View {
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isExporting {
                            VStack(spacing: 16) {
                                ProgressView(value: exportProgress)
                                    .tint(Color(red: 0.0, green: 0.8, blue: 0.6))
                                Text("Preparing your data export...")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(40)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            .padding(24)
                        } else {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color(red: 0.0, green: 0.8, blue: 0.6).opacity(0.15))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "square.and.arrow.up.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.6))
                                }
                                
                                Text("Export Your Data")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Text("Download a copy of your business plans, goals, notes, and progress data.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                            .padding(24)
                            
                            Button {
                                startExport()
                            } label: {
                                Text("Export Data")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(red: 0.0, green: 0.8, blue: 0.6))
                                    .cornerRadius(16)
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
        }
    }
    
    private func startExport() {
        isExporting = true
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            exportProgress += 0.1
            
            if exportProgress >= 1.0 {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(BusinessPlanStore())
    }
}