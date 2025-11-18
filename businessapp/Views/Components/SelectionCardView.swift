import SwiftUI

struct SelectionCardView: View {
    @Binding var question: Question
    @Binding var selectedEntry: [Bool]
    let queryIndex: Int
    let selectedIndex: Int
    // Called when this option becomes selected or its custom text changes
    var onSelect: ((String?) -> Void)?
    
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
                // if option is an Other-type, we may want to keep using question.selectedOption (filled via TextField)
                if let a = answer, a.lowercased().contains("other") || a.lowercased().contains("something else") || a.lowercased().contains("tell us") {
                    // if there's existing custom text, use that; otherwise use the option label as placeholder
                    onSelect?(question.selectedOption ?? "")
                } else {
                    onSelect?(answer)
                }
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke((selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) ? ModernDesign.Colors.successLight : ModernDesign.Colors.gray300, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if (selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) {
                        Circle()
                            .fill(ModernDesign.Colors.successLight)
                            .frame(width: 12, height: 12)
                            .shadow(color: ModernDesign.Colors.success.opacity(0.12), radius: 6, x: 0, y: 2)
                    }
                }
                
                            VStack(alignment: .leading, spacing: 8) {
                                // Question.options holds the option strings
                                if selectedIndex < question.options.count {
                                    Text(question.options[selectedIndex])
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ModernDesign.Colors.gray900)
                                } else {
                                    Text("")
                                        .font(.system(size: 16, weight: .semibold))
                                }

                                // If this option is an "Other"-type and currently selected, show a text field for custom input
                                let option = selectedIndex < question.options.count ? question.options[selectedIndex].lowercased() : ""
                                if (selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) && (option.contains("other") || option.contains("something else") || option.contains("tell us") ) {
                                    TextField("Please describe...", text: Binding(
                                        get: { question.selectedOption ?? "" },
                                        set: { newVal in
                                            question.selectedOption = newVal
                                            onSelect?(newVal)
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 14))
                                }
                            }
                
                Spacer()
                
                // No image data available in the current Question model; keep layout compact
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke((selectedIndex < selectedEntry.count ? selectedEntry[selectedIndex] : false) ? ModernDesign.Colors.successLight.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .scaleEffect(selectedEntry.count > selectedIndex && selectedEntry[selectedIndex] ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedEntry.count > selectedIndex ? selectedEntry[selectedIndex] : false)
        .onAppear {
            if selectedEntry.count < question.options.count {
                selectedEntry.append(contentsOf: Array(repeating: false, count: question.options.count - selectedEntry.count))
            }
        }
    }
}
