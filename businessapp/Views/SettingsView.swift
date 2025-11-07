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
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Card
                    ModernCard(
                        gradient: AppColors.vibrantGradient,
                        padding: 24
                    ) {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(AppColors.primaryGradient)
                                .frame(width: 70, height: 70)
                                .overlay {
                                    Text(initials)
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(displayName)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text(userEmail)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                if let profile = businessPlanStore.userProfile {
                                    HStack {
                                        ColorfulBadge("\(profile.skills.count) skills", color: .white.opacity(0.9))
                                        ColorfulBadge("\(profile.interests.count) interests", color: .white.opacity(0.9))
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    .fadeInUp()
                    
                    // Profile Actions
                    VStack(spacing: 12) {
                        ActionCard(
                            title: "Edit Profile",
                            subtitle: "Update your information",
                            icon: "person.circle.fill",
                            color: AppColors.primaryOrange
                        ) {
                            // Navigate to profile editing
                        }
                        
                        ActionCard(
                            title: "Retake Quiz",
                            subtitle: "Refresh your business ideas",
                            icon: "sparkles",
                            color: AppColors.brightBlue
                        ) {
                            showingOnboarding = true
                        }
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp(delay: 0.1)
                    
                    // Preferences
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preferences")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        ModernCard(padding: 20) {
                            VStack(spacing: 16) {
                                ToggleRow(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    isOn: $notificationsEnabled,
                                    color: AppColors.primaryOrange
                                )
                                
                                Divider()
                                
                                ToggleRow(
                                    icon: "sparkles",
                                    title: "AI Suggestions",
                                    isOn: $aiSuggestionsEnabled,
                                    color: AppColors.primaryPink
                                )
                                
                                Divider()
                                
                                ToggleRow(
                                    icon: "envelope.fill",
                                    title: "Weekly Emails",
                                    isOn: $weeklyEmailsEnabled,
                                    color: AppColors.brightBlue
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .fadeInUp(delay: 0.2)
                    
                    // AI Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Settings")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        AISettingsCard()
                            .padding(.horizontal, 24)
                    }
                    .fadeInUp(delay: 0.25)
                    
                    // Data & Privacy
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data & Privacy")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ActionCard(
                                title: "Export Data",
                                subtitle: "Download your information",
                                icon: "square.and.arrow.up",
                                color: AppColors.duolingoGreen
                            ) {
                                showingExportData = true
                            }
                            
                            ActionCard(
                                title: "Privacy Policy",
                                subtitle: "How we protect your data",
                                icon: "shield.fill",
                                color: AppColors.brightBlue
                            ) {
                                // Open privacy policy
                            }
                            
                            ActionCard(
                                title: "Terms of Service",
                                subtitle: "Legal information",
                                icon: "doc.text.fill",
                                color: AppColors.primaryOrange
                            ) {
                                // Open terms
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .fadeInUp(delay: 0.3)
                    
                    // Support
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ActionCard(
                                title: "Help Center",
                                subtitle: "Get answers to questions",
                                icon: "questionmark.circle.fill",
                                color: AppColors.primaryOrange
                            ) {
                                // Open help
                            }
                            
                            ActionCard(
                                title: "Contact Support",
                                subtitle: "Reach out for assistance",
                                icon: "envelope.fill",
                                color: AppColors.brightBlue
                            ) {
                                // Open contact form
                            }
                            
                            ActionCard(
                                title: "Rate App",
                                subtitle: "Share your feedback",
                                icon: "star.fill",
                                color: AppColors.primaryPink
                            ) {
                                // Request app review
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .fadeInUp(delay: 0.4)
                    
                    // Account Actions
                    VStack(spacing: 12) {
                        PlayfulButton(
                            title: "Sign Out",
                            icon: "arrow.right.square.fill",
                            gradient: LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        ) {
                            showingSignOut = true
                        }
                        
                        Button {
                            showingDeleteAccount = true
                        } label: {
                            Text("Delete Account")
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp(delay: 0.5)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
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
            OnboardingFlow()
        }
        .sheet(isPresented: $showingExportData) {
            ExportDataView()
        }
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

private struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(color)
        }
    }
}

private struct ExportDataView: View {
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isExporting {
                            ModernCard(padding: 40) {
                                VStack(spacing: 16) {
                                    ProgressView(value: exportProgress)
                                        .tint(AppColors.primaryOrange)
                                    Text("Preparing your data export...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(24)
                        } else {
                            ModernCard(padding: 40) {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(AppColors.primaryOrange.opacity(0.15))
                                            .frame(width: 80, height: 80)
                                        Image(systemName: "square.and.arrow.up.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundStyle(AppColors.primaryGradient)
                                    }
                                    
                                    Text("Export Your Data")
                                        .font(.headline)
                                    
                                    Text("Download a copy of your business plans, goals, notes, and progress data.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(24)
                            
                            ModernCard(padding: 20) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Included in export")
                                        .font(.headline)
                                    
                                    ExportItem("Business ideas and analysis")
                                    ExportItem("Goals and milestones")
                                    ExportItem("Notes and insights")
                                    ExportItem("Progress tracking data")
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            PlayfulButton(
                                title: "Export Data",
                                icon: "square.and.arrow.up.fill",
                                gradient: AppColors.primaryGradient
                            ) {
                                startExport()
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

private struct ExportItem: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.duolingoGreen)
            Text(text)
                .font(.body)
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
