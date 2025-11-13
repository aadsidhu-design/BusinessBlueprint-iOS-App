import SwiftUI

struct SelectionCardView: View {
    @Binding var question: Question
    @Binding var selectedEntry: [Bool]
    let queryIndex: Int
    let selectedIndex: Int
    
    var body: some View {
        Button(action: {
            // Deselect all first, then select current
            for i in 0..<selectedEntry.count {
                selectedEntry[i] = false
            }
            selectedEntry[selectedIndex] = true
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(selectedEntry[selectedIndex] ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if selectedEntry[selectedIndex] {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                    }
                }
                
                            VStack(alignment: .leading, spacing: 4) {
                                // Question.options holds the option strings
                                if selectedIndex < question.options.count {
                                    Text(question.options[selectedIndex])
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.black)
                                } else {
                                    Text("")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                
                Spacer()
                
                // No image data available in the current Question model; keep layout compact
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedEntry[selectedIndex] ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedEntry[selectedIndex] ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
