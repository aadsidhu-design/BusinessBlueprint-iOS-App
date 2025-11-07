import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var showBrainDump = false
    @State private var showIdeaGenerator = false
    @State private var selectedIdea: BusinessIdea?
    
    private var firstName: String {
        businessPlanStore.userProfile?.firstName ?? "there"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        VStack(spacing: 16) {
                            Text("Discover Your")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Perfect Business Idea")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryGradient)
                            
                            Text("AI-powered tools to help you brainstorm, validate, and plan your entrepreneurial journey")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .padding(.top, 8)
                        }
                        .padding(.top, 40)
                        .fadeInUp()
                        
                        // Main Actions
                        VStack(spacing: 16) {
                            DiscoverActionCard(
                                title: "Brain Dump",
                                subtitle: "Share your thoughts, let AI organize them into ideas",
                                icon: "brain.head.profile",
                                gradient: AppColors.primaryGradient,
                                iconSize: 32
                            ) {
                                showBrainDump = true
                                HapticManager.shared.trigger(.medium)
                            }
                            .fadeInUp(delay: 0.1)
                            
                            DiscoverActionCard(
                                title: "Generate Ideas",
                                subtitle: "Answer a few questions and get personalized business ideas",
                                icon: "sparkles",
                                gradient: AppColors.successGradient,
                                iconSize: 32
                            ) {
                                showIdeaGenerator = true
                                HapticManager.shared.trigger(.medium)
                            }
                            .fadeInUp(delay: 0.2)
                        }
                        .padding(.horizontal, 24)
                        
                        // Recent Ideas
                        if !businessPlanStore.businessIdeas.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Your Ideas")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(businessPlanStore.businessIdeas.count)")
                                        .font(.title3.bold())
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(Array(businessPlanStore.businessIdeas.prefix(5).enumerated()), id: \.element.id) { index, idea in
                                            BusinessIdeaCard(idea: idea) {
                                                selectedIdea = idea
                                                businessPlanStore.selectedIdeaID = idea.id
                                                HapticManager.shared.trigger(.success)
                                            }
                                            .frame(width: 280)
                                            .fadeInUp(delay: Double(index) * 0.1)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            .fadeInUp(delay: 0.3)
                        }
                        
                        // Inspirational Quote Section
                        ModernCard(
                            gradient: LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            padding: 24
                        ) {
                            VStack(spacing: 12) {
                                Image(systemName: "quote.opening")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                Text("The best time to plant a tree was 20 years ago. The second best time is now.")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .italic()
                                
                                Text("— Chinese Proverb")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)
                        .fadeInUp(delay: 0.4)
                        
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showBrainDump) {
                BrainDumpView()
                    .environmentObject(businessPlanStore)
            }
            .sheet(isPresented: $showIdeaGenerator) {
                AIIdeaGeneratorView()
                    .environmentObject(businessPlanStore)
            }
        }
    }
}

private struct DiscoverActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let iconSize: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: iconSize, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct BusinessIdeaCard: View {
    let idea: BusinessIdea
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.primaryGradient)
                    
                    Spacer()
                    
                    if idea.progress > 0 {
                        Text("\(idea.progress)%")
                            .font(.caption.bold())
                            .foregroundColor(AppColors.primaryOrange)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(idea.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack(spacing: 8) {
                    CategoryTag(text: idea.category)
                    CategoryTag(text: idea.difficulty)
                }
                
                if idea.progress > 0 {
                    ProgressView(value: Double(idea.progress), total: 100)
                        .tint(AppColors.primaryOrange)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct CategoryTag: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
            )
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    DiscoverView()
        .environmentObject(BusinessPlanStore())
}
