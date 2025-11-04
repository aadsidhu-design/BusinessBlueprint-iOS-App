import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var showPremiumOptions = false
    
    private var profile: UserProfile {
        businessPlanStore.userProfile ?? UserProfile(
            id: UUID().uuidString,
            email: "founder@example.com",
            firstName: "Founder",
            lastName: "",
            skills: [],
            personality: [],
            interests: [],
            createdAt: Date(),
            subscriptionTier: "free"
        )
    }
    
    private var ideaCount: Int {
        businessPlanStore.businessIdeas.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.1, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 1, green: 0.6, blue: 0.2),
                                                Color(red: 1, green: 0.4, blue: 0.1)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 20, height: 20)
                            }
                            
                            VStack(spacing: 4) {
                                Text("\(profile.firstName) \(profile.lastName)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(profile.email)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            SubscriptionBadge(tier: profile.subscriptionTier)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(16)
                        .padding(20)
                        
                        // Stats
                        HStack(spacing: 12) {
                            ProfileStat(number: "\(ideaCount)", label: "Ideas")
                            ProfileStat(number: "0", label: "Goals")
                            ProfileStat(number: "0", label: "Milestones")
                        }
                        .padding(.horizontal, 20)
                        
                        // Profile Information
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Your Profile")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            ProfileInfoSection(title: "Skills", items: profile.skills)
                            ProfileInfoSection(title: "Personality", items: profile.personality)
                            ProfileInfoSection(title: "Interests", items: profile.interests)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Premium Section
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("Upgrade to Premium")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    
                                    Text("Unlock unlimited ideas & AI consulting")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showPremiumOptions = true
                            }
                        }
                        .padding(16)
                        .background(Color(red: 1, green: 0.6, blue: 0.2).opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        
                        // Settings Section
                        VStack(spacing: 12) {
                            SettingRow(icon: "bell.fill", title: "Notifications", value: "On")
                            SettingRow(icon: "lock.fill", title: "Privacy", value: "Public")
                            SettingRow(icon: "questionmark.circle.fill", title: "Help", value: "")
                            SettingRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", value: "")
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPremiumOptions) {
            PremiumPlanView(isPresented: $showPremiumOptions)
        }
    }
}

struct SubscriptionBadge: View {
    let tier: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: tier == "premium" ? "star.fill" : "circle.fill")
                .font(.system(size: 10))
            
            Text(tier.uppercased())
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            tier == "premium" ?
            Color(red: 1, green: 0.6, blue: 0.2).opacity(0.3) :
            Color.white.opacity(0.1)
        )
        .foregroundColor(
            tier == "premium" ?
            Color(red: 1, green: 0.6, blue: 0.2) :
            .white
        )
        .cornerRadius(8)
    }
}

struct ProfileStat: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(number)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

struct ProfileInfoSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            
            if items.isEmpty {
                Text("None selected")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(red: 1, green: 0.6, blue: 0.2).opacity(0.3))
                            .cornerRadius(6)
                            .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                    }
                }
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            if !value.isEmpty {
                Text(value)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(10)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        var height: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > (proposal.width ?? 300) {
                height += currentRowHeight + spacing
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth += size.width + spacing
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }
        
        height += currentRowHeight
        return CGSize(width: proposal.width ?? 300, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: size.width, height: size.height))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct PremiumPlanView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.15, blue: 0.35),
                        Color(red: 0.1, green: 0.2, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.yellow)
                                
                                Text("Unlock Premium")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 16) {
                                PlanOption(
                                    title: "Pro",
                                    price: "$9.99",
                                    period: "/month",
                                    features: [
                                        "✓ Unlimited business ideas",
                                        "✓ AI consulting (5/month)",
                                        "✓ Advanced analytics",
                                        "✓ Export reports"
                                    ],
                                    isPopular: false
                                )
                                
                                PlanOption(
                                    title: "Premium",
                                    price: "$19.99",
                                    period: "/month",
                                    features: [
                                        "✓ Everything in Pro",
                                        "✓ Unlimited AI consulting",
                                        "✓ Priority support",
                                        "✓ GitHub integration",
                                        "✓ Advanced forecasting"
                                    ],
                                    isPopular: true
                                )
                                
                                PlanOption(
                                    title: "Lifetime",
                                    price: "$199.99",
                                    period: "one-time",
                                    features: [
                                        "✓ All Premium features forever",
                                        "✓ Priority support",
                                        "✓ Early access to new features",
                                        "✓ Lifetime updates"
                                    ],
                                    isPopular: false
                                )
                            }
                            .padding(20)
                        }
                    }
                    
                    Button(action: { isPresented = false }) {
                        Text("Continue with Free")
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Choose Your Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct PlanOption: View {
    let title: String
    let price: String
    let period: String
    let features: [String]
    let isPopular: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Text(price)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 1, green: 0.6, blue: 0.2))
                        
                        Text(period)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                if isPopular {
                    Text("POPULAR")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 1, green: 0.6, blue: 0.2))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    Text(feature)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Button(action: {}) {
                Text("Choose \(title)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        isPopular ?
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 1, green: 0.6, blue: 0.2),
                                Color(red: 1, green: 0.4, blue: 0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.15)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(16)
        .background(isPopular ? Color(red: 1, green: 0.6, blue: 0.2).opacity(0.1) : Color.white.opacity(0.05))
        .border(isPopular ? Color(red: 1, green: 0.6, blue: 0.2) : Color.clear, width: isPopular ? 2 : 0)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
}
