import SwiftUI

struct EnhancedCoachView: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    @State private var userMessage = ""
    @State private var messages: [OldChatMessage] = []
    @State private var isLoading = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Coach")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text("Your personal growth guide")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(AppColors.primary.opacity(0.2))
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primary)
                        }
                        .frame(width: 44, height: 44)
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.9), AppColors.accent.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
                
                // Chat
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if messages.isEmpty {
                                WelcomeMessage()
                                    .id("welcome")
                            } else {
                                ForEach(messages, id: \.id) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            
                            if isLoading {
                                HStack(spacing: 4) {
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .fill(Color.white.opacity(0.6))
                                            .frame(width: 8, height: 8)
                                            .animation(
                                                .easeInOut(duration: 0.6)
                                                    .repeatForever()
                                                    .delay(Double(index) * 0.1),
                                                value: isLoading
                                            )
                                    }
                                }
                                .padding(16)
                                .id("loading")
                            }
                        }
                        .padding(16)
                        .onChange(of: messages.count) {
                            withAnimation {
                                if let lastId = messages.last?.id {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                } else {
                                    proxy.scrollTo("welcome", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isLoading) {
                            if isLoading {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // Quick Actions
                if messages.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(QuickActionType.allCases, id: \.self) { action in
                            OldQuickActionButton(type: action) {
                                sendMessage(action.prompt)
                            }
                        }
                    }
                    .padding(16)
                }
                
                // Input
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Ask for advice...", text: $userMessage)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                        
                        Button(action: { sendMessage() }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(AppColors.primary)
                        }
                        .disabled(userMessage.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private func sendMessage(_ text: String? = nil) {
        let messageText = (text ?? userMessage).trimmingCharacters(in: .whitespaces)
        guard !messageText.isEmpty else { return }
        
        userMessage = ""
        messages.append(OldChatMessage(content: messageText, isFromUser: true))
        isLoading = true
        
        timelineVM.askAIAboutProgress(question: messageText) { response in
            DispatchQueue.main.async {
                isLoading = false
                messages.append(OldChatMessage(content: response, isFromUser: false))
            }
        }
    }
}

private struct WelcomeMessage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.15))
                    Image(systemName: "sparkles")
                        .foregroundColor(AppColors.primary)
                }
                .frame(width: 36, height: 36)
                
                Text("AI Coach")
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            Text("Hi! I'm your personal AI coach here to guide you through your entrepreneurial journey. Ask me anything about your goals, progress, or need advice!")
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [AppColors.primary.opacity(0.15), AppColors.accent.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .padding(.vertical, 12)
    }
}

private struct ChatBubble: View {
    let message: OldChatMessage
    
    var body: some View {
        HStack(spacing: 12) {
            if message.isFromUser {
                Spacer()
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
            } else {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "sparkles")
                        .font(.caption.bold())
                        .foregroundColor(AppColors.primary)
                }
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

private struct OldQuickActionButton: View {
    let type: QuickActionType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(type.title)
                    .font(.headline)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [type.color.opacity(0.3), type.color.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

enum QuickActionType: CaseIterable {
    case progress
    case motivation
    case nextStep
    case goalSetting
    
    var title: String {
        switch self {
        case .progress: return "Show my progress"
        case .motivation: return "Motivate me"
        case .nextStep: return "What's next?"
        case .goalSetting: return "Help with goals"
        }
    }
    
    var prompt: String {
        switch self {
        case .progress: return "Show me my progress and what I've accomplished so far."
        case .motivation: return "Give me some motivation to keep going!"
        case .nextStep: return "What should I focus on next?"
        case .goalSetting: return "Help me set realistic goals for the next week."
        }
    }
    
    var icon: String {
        switch self {
        case .progress: return "chart.line.uptrend.xyaxis"
        case .motivation: return "flame.fill"
        case .nextStep: return "arrow.right.circle.fill"
        case .goalSetting: return "target"
        }
    }
    
    var color: Color {
        switch self {
        case .progress: return AppColors.brightBlue
        case .motivation: return AppColors.primaryOrange
        case .nextStep: return AppColors.duolingoGreen
        case .goalSetting: return AppColors.primary
        }
    }
}

#Preview {
    EnhancedCoachView(timelineVM: IslandTimelineViewModel())
}
