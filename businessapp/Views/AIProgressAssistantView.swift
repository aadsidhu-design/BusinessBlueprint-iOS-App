import SwiftUI

struct AIProgressAssistantView: View {
    @ObservedObject var viewModel: IslandTimelineViewModel
    let showsCloseButton: Bool
    @State private var userQuestion = ""
    @State private var messages: [OldChatMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(viewModel: IslandTimelineViewModel, showsCloseButton: Bool = true) {
        self._viewModel = ObservedObject(initialValue: viewModel)
        self.showsCloseButton = showsCloseButton
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            if messages.isEmpty {
                                ModernCard(
                                    gradient: AppColors.vibrantGradient,
                                    padding: 32
                                ) {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.25))
                                                .frame(width: 80, height: 80)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("Your AI Business Guide")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Text("I'm here to help you navigate your journey! Ask me anything about your progress, goals, or next steps.")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.9))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding()
                                .bounceEntrance()
                            }
                            
                            ForEach(messages) { message in
                                OldMessageBubble(message: message)
                                    .id(message.id)
                                    .fadeInUp()
                            }
                            
                            if isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(AppColors.primaryOrange)
                                    Text("Thinking...")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) {
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick Actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        QuickActionChip(icon: "chart.line.uptrend.xyaxis", text: "Show my progress", color: AppColors.primaryOrange) {
                            sendMessage("Show my progress")
                        }
                        QuickActionChip(icon: "lightbulb.fill", text: "Give me a tip", color: AppColors.brightBlue) {
                            sendMessage("Give me a tip")
                        }
                        QuickActionChip(icon: "flag.fill", text: "What's next?", color: AppColors.duolingoGreen) {
                            sendMessage("What's next?")
                        }
                        QuickActionChip(icon: "target", text: "Set a new goal", color: AppColors.primaryPink) {
                            sendMessage("Set a new goal")
                        }
                    }
                    .padding()
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Ask me anything...", text: $userQuestion, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                        .disabled(isLoading)
                    
                    Button {
                        sendMessage(userQuestion)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(userQuestion.isEmpty ? .gray : AppColors.primaryOrange)
                    }
                    .disabled(userQuestion.isEmpty || isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationTitle(showsCloseButton ? "AI Guide" : "AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("AI Service", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        guard !text.isEmpty, !isLoading else { return }
        
        let userMessage = OldChatMessage(content: text, isFromUser: true)
        messages.append(userMessage)
        userQuestion = ""
        isLoading = true
        HapticManager.shared.trigger(.light)
        
        viewModel.askAIAboutProgress(question: text) { response in
            DispatchQueue.main.async {
                self.isLoading = false
                let aiMessage = OldChatMessage(content: response, isFromUser: false)
                self.messages.append(aiMessage)
                
                if response.contains("⚠️") || response.contains("not configured") || response.contains("trouble connecting") {
                    self.errorMessage = response
                }
            }
        }
    }
}

struct OldChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
}

private struct OldMessageBubble: View {
    let message: OldChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(16)
                    .background(
                        Group {
                            if message.isFromUser {
                                AppColors.blueGradient
                            } else {
                                Color(.systemGray5)
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
            .padding(.horizontal)
            
            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
}

private struct QuickActionChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            action()
            HapticManager.shared.trigger(.light)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(AnimationHelpers.buttonPress, value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    AIProgressAssistantView(viewModel: IslandTimelineViewModel())
}
