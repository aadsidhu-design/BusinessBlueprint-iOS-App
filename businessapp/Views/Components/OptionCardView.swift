import SwiftUI

struct OptionCardView: View {
    @Binding var question: Question
    @Binding var selectedEntry: [Bool]
    let selectedIndex: Int
    let optionText: String
    var onSelect: ((String?) -> Void)?
    
    // Dynamic icons based on option keywords
    var cardIcon: String {
        let lower = optionText.lowercased()
        if lower.contains("tech") || lower.contains("app") || lower.contains("coding") { return "💻" }
        if lower.contains("e-commerce") || lower.contains("sales") || lower.contains("products") { return "🛍️" }
        if lower.contains("health") || lower.contains("wellness") { return "🏥" }
        if lower.contains("finance") || lower.contains("investing") || lower.contains("money") { return "💰" }
        if lower.contains("education") || lower.contains("coaching") { return "📚" }
        if lower.contains("creative") || lower.contains("content") || lower.contains("arts") { return "🎨" }
        if lower.contains("leadership") || lower.contains("strategy") { return "👔" }
        if lower.contains("marketing") || lower.contains("sales") { return "📊" }
        if lower.contains("design") || lower.contains("visual") { return "🎭" }
        if lower.contains("network") || lower.contains("connecting") { return "🤝" }
        if lower.contains("other") { return "✨" }
        return "⭐"
    }
    
    var body: some View {
        Button(action: {
            // Ensure the selectedEntry array is large enough before mutating
            if selectedEntry.count <= selectedIndex {
                selectedEntry.append(contentsOf: Array(repeating: false, count: selectedIndex - selectedEntry.count + 1))
            }
            
            if question.allowsMultiple {
                // toggle selection
                selectedEntry[selectedIndex].toggle()
                // for multiple selection, build comma-separated answer
                var chosen: [String] = []
                for i in 0..<selectedEntry.count where selectedEntry[i] {
                    if i < question.options.count {
                        chosen.append(question.options[i])
                    }
                }
                let answer = chosen.joined(separator: ", ")
                onSelect?(answer)
            } else {
                // single selection: deselect others and select current
                for i in 0..<selectedEntry.count {
                    selectedEntry[i] = false
                }
                selectedEntry[selectedIndex] = true
                let answer = selectedIndex < question.options.count ? question.options[selectedIndex] : nil
                if let a = answer, a.lowercased().contains("other") || a.lowercased().contains("something else") || a.lowercased().contains("tell us") {
                    onSelect?(question.selectedOption ?? "")
                } else {
                    onSelect?(answer)
                }
            }
        }) {
            HStack(spacing: 12) {
                // Radio button / Checkbox
                ZStack {
                    let isSelected = (selectedIndex < selectedEntry.count) ? selectedEntry[selectedIndex] : false
                    
                    Circle()
                        .stroke(isSelected ? ModernDesign.Colors.successLight : ModernDesign.Colors.gray300, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(ModernDesign.Colors.successLight)
                            .frame(width: 12, height: 12)
                            .shadow(color: ModernDesign.Colors.success.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                }
                .flexibleFrame(horizontal: 24, vertical: 24)
                
                // Title and subtitle
                VStack(alignment: .leading, spacing: 4) {
                    Text(optionText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(ModernDesign.Colors.gray900)
                        .lineLimit(2)

                    // Subtitle based on option content
                    let subtitle = getSubtitle(for: optionText)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(ModernDesign.Colors.gray600)
                            .lineLimit(1)
                    }
                    
                    // Custom input field for "Other" options
                    let lower = optionText.lowercased()
                    if (selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) && 
                       (lower.contains("other") || lower.contains("something else") || lower.contains("tell us")) {
                        TextField("Please describe...", text: Binding(
                            get: { question.selectedOption ?? "" },
                            set: { newVal in
                                question.selectedOption = newVal
                                onSelect?(newVal)
                            }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13))
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Card icon
                Text(cardIcon)
                    .font(.system(size: 28))
                    .foregroundColor(ModernDesign.Colors.successLight)
                    .opacity(0.95)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((selectedIndex < selectedEntry.count && selectedEntry[selectedIndex]) ? ModernDesign.Colors.successLight.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .scaleEffect((selectedIndex < selectedEntry.count && selectedEntry[selectedIndex]) ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedEntry.count > selectedIndex ? (selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) : false)
        .onAppear {
            if selectedEntry.count < question.options.count {
                selectedEntry.append(contentsOf: Array(repeating: false, count: question.options.count - selectedEntry.count))
            }
        }
    }
    
    private func getSubtitle(for option: String) -> String {
        let lower = option.lowercased()
        
        // Map option texts to descriptive subtitles
        if lower.contains("tech") || lower.contains("app") { return "Build digital products" }
        if lower.contains("e-commerce") || lower.contains("sales") { return "Sell online products" }
        if lower.contains("health") || lower.contains("wellness") { return "Help people get healthier" }
        if lower.contains("finance") || lower.contains("investing") { return "Manage investments" }
        if lower.contains("education") || lower.contains("coaching") { return "Share your expertise" }
        if lower.contains("creative") || lower.contains("content") { return "Express your creativity" }
        if lower.contains("leadership") || lower.contains("strategy") { return "Guide teams & vision" }
        if lower.contains("marketing") { return "Grow & reach audiences" }
        if lower.contains("design") || lower.contains("visual") { return "Create beautiful designs" }
        if lower.contains("network") { return "Build meaningful connections" }
        if lower.contains("time") { return "Manage your schedule" }
        if lower.contains("money") || lower.contains("funding") { return "Financial resources" }
        if lower.contains("knowledge") || lower.contains("skills") { return "Leverage expertise" }
        if lower.contains("confidence") { return "Build self-assurance" }
        if lower.contains("connection") || lower.contains("network") { return "Professional networks" }
        
        return ""
    }
}

extension View {
    func flexibleFrame(horizontal: CGFloat? = nil, vertical: CGFloat? = nil) -> some View {
        self.frame(width: horizontal, height: vertical)
    }
}

#Preview {
    OptionCardView(
        question: .constant(StaticQuestions.questions.first ?? Question(id: "test", text: "Test", options: ["Option 1", "Option 2"])),
        selectedEntry: .constant([false, false]),
        selectedIndex: 0,
        optionText: "Tech & apps"
    )
}
