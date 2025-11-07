import SwiftUI

struct AssistantExperienceView: View {
    @EnvironmentObject private var experienceVM: ExperienceViewModel
    @EnvironmentObject private var businessPlanStore: BusinessPlanStore
    @State private var quickPrompt: String = ""
    @State private var assistantIdea: BusinessIdea?
    @FocusState private var promptFocused: Bool
    
    private var selectedIdea: BusinessIdea? { businessPlanStore.selectedBusinessIdea }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    ModernCard(
                        gradient: AppColors.vibrantGradient,
                        padding: 24
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.25))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 30))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Assistant")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("Your AI co-founder, always ready to help")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                            
                            if let idea = selectedIdea {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.white.opacity(0.9))
                                    Text(idea.title)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.white.opacity(0.9))
                                    Text("Select a business idea first")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    .fadeInUp()
                    
                    // Prompt Input
                    ModernCard(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ask Anything")
                                .font(.headline)
                            
                            ModernTextField(
                                title: "",
                                text: $quickPrompt,
                                placeholder: "e.g. Help me prioritize this week",
                                icon: "message.fill"
                            )
                            
                            PlayfulButton(
                                title: promptFocused ? "Send to assistant" : "Save as note",
                                icon: promptFocused ? "paperplane.fill" : "note.text",
                                gradient: AppColors.primaryGradient,
                                disabled: quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ) {
                                submitPrompt()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .fadeInUp(delay: 0.1)
                    
                    // Quick Suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Suggestions")
                            .font(.headline)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                OldQuickSuggestionChip(
                                    icon: "lightbulb.fill",
                                    text: "How can I validate my idea this week?",
                                    color: AppColors.primaryOrange
                                ) {
                                    quickPrompt = "How can I validate my idea this week?"
                                    promptFocused = true
                                }
                                
                                OldQuickSuggestionChip(
                                    icon: "chart.line.uptrend.xyaxis",
                                    text: "What metrics should I watch?",
                                    color: AppColors.brightBlue
                                ) {
                                    quickPrompt = "What metrics should I watch right now?"
                                    promptFocused = true
                                }
                                
                                OldQuickSuggestionChip(
                                    icon: "doc.text",
                                    text: "Help with investor update",
                                    color: AppColors.primaryPink
                                ) {
                                    quickPrompt = "Help me craft an investor update"
                                    promptFocused = true
                                }
                                
                                OldQuickSuggestionChip(
                                    icon: "exclamationmark.triangle.fill",
                                    text: "What's my biggest risk?",
                                    color: AppColors.primaryOrange
                                ) {
                                    quickPrompt = "What's my biggest competitive risk?"
                                    promptFocused = true
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .fadeInUp(delay: 0.2)
                    
                    // Recent Notes
                    if !experienceVM.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Notes")
                                .font(.headline)
                                .padding(.horizontal, 24)
                            
                            ForEach(experienceVM.notes.prefix(5)) { note in
                                ModernCard(padding: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(note.content)
                                            .font(.body)
                                        Text(note.createdAt, style: .relative)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        .fadeInUp(delay: 0.3)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Assistant")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $assistantIdea) { idea in
            AIAssistantView(businessIdea: idea)
        }
    }
    
    private func submitPrompt() {
        let trimmed = quickPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        experienceVM.addNote(content: trimmed)
        quickPrompt = ""
        promptFocused = false
        HapticManager.shared.trigger(.success)
    }
}

private struct OldQuickSuggestionChip: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            action()
            HapticManager.shared.trigger(.light)
        }) {
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
    NavigationStack {
        AssistantExperienceView()
            .environmentObject(ExperienceViewModel())
            .environmentObject(BusinessPlanStore())
    }
}
