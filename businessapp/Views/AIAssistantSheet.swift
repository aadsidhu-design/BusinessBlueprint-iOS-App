import SwiftUI

struct AIAssistantSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @StateObject private var contextManager = IntelligentContextManager.shared
    private let aiService = GoogleAIService.shared
    
    @State private var messages: [AssistantMessage] = []
    @State private var inputText = ""
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0F172A")
                    .ignoresSafeArea()
                    .onTapGesture {
                        hideKeyboard()
                    }
                
                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome Message
                                if messages.isEmpty {
                                    welcomeView
                                }
                                
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isProcessing {
                                    TypingIndicator()
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: messages.count) {
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    inputArea
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "6366F1"))
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private var welcomeView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "6366F1"))
            
            Text("Hi! I'm your AI Assistant")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text("I know everything about your business journey. Ask me anything - about your ideas, timelines, notes, or get advice on what to do next.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Quick Actions
            VStack(spacing: 12) {
                QuickActionButton(text: "What should I work on next?", action: sendMessage)
                QuickActionButton(text: "Analyze my progress", action: sendMessage)
                QuickActionButton(text: "Help me refine my idea", action: sendMessage)
            }
            .padding(.top, 20)
        }
        .padding(.top, 40)
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask me anything...", text: $inputText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .onSubmit {
                    sendMessage(inputText)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .cornerRadius(24)
            
            Button(action: { sendMessage() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(inputText.isEmpty ? .white.opacity(0.3) : Color(hex: "6366F1"))
            }
            .disabled(inputText.isEmpty || isProcessing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(hex: "1E293B"))
    }
    
    private func sendMessage(_ text: String? = nil) {
        let messageText = text ?? inputText
        guard !messageText.isEmpty else { return }
        
        let userMessage = AssistantMessage(content: messageText, isFromUser: true)
        messages.append(userMessage)
        inputText = ""
        isProcessing = true
        
        // Record in context
        contextManager.recordAction(
            .aiConversation(message: messageText, response: ""),
            metadata: ["type": "assistant_chat"]
        )
        
        // Build context for AI
        let fullContext = buildContextPrompt()
        let prompt = """
        \(fullContext)
        
        User question: \(messageText)
        
        Provide a helpful, specific response based on the context above. Be conversational and actionable.
        """
        
        aiService.makeAIRequest(prompt: prompt) { result in
            Task { @MainActor in
                isProcessing = false
                
                switch result {
                case .success(let response):
                    let aiMessage = AssistantMessage(content: response, isFromUser: false)
                    messages.append(aiMessage)
                    
                    // Update context with AI response
                    contextManager.recordAction(
                        .aiConversation(message: messageText, response: response),
                        metadata: ["type": "assistant_response"]
                    )
                    
                case .failure(let error):
                    let errorMessage = AssistantMessage(
                        content: "I'm sorry, I encountered an error. Please try again.",
                        isFromUser: false
                    )
                    messages.append(errorMessage)
                    print("AI Error: \(error)")
                }
            }
        }
    }
    
    private func buildContextPrompt() -> String {
        var context = "Context about the user:\n\n"
        
        // Business Ideas
        if !businessPlanStore.businessIdeas.isEmpty {
            context += "Business Ideas:\n"
            for idea in businessPlanStore.businessIdeas.prefix(3) {
                context += "- \(idea.title): \(idea.description) (Progress: \(Int(idea.progress * 100))%)\n"
            }
            context += "\n"
        }
        
        // Selected Idea
        if let selected = businessPlanStore.selectedBusinessIdea {
            context += "Currently working on: \(selected.title)\n"
            context += "Description: \(selected.description)\n\n"
        }
        
        // User Insights
        let insights = contextManager.userInsights
        if !insights.businessFocusAreas.isEmpty {
            context += "Focus areas: \(insights.businessFocusAreas.joined(separator: ", "))\n"
        }
        
        // Recent actions
        let recentActions = contextManager.contextEntries.suffix(5)
        if !recentActions.isEmpty {
            context += "\nRecent activity:\n"
            for entry in recentActions {
                context += "- \(entry.action.actionType)\n"
            }
        }
        
        return context
    }
}

struct AssistantMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: AssistantMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(message.isFromUser ? .white : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isFromUser
                            ? LinearGradient(
                                colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                    )
                    .cornerRadius(20)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animationAmount = 2.0
            }
        }
    }
}

struct QuickActionButton: View {
    let text: String
    let action: (String) -> Void
    
    var body: some View {
        Button(action: { action(text) }) {
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6366F1"))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(hex: "6366F1").opacity(0.1))
                .cornerRadius(20)
        }
    }
}