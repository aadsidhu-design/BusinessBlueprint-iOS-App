//
//  OnboardingQuestionaireView.swift
//  businessapp
//
//  Created by Євген Жадан on 06.11.2025.
//

import SwiftUI

struct OnboardingQuestionaireView: View {
    @State private var progress = 0.1  // Progress bar value
    @State private var index = 0  // Index of presented view
    @State private var selectedEntry: [Bool] = []
    @StateObject var viewModel = OnboardingViewModel()
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    let questionSubtitles: [String] = [
        "Build digital products",
        "Sell online products",
        "Help people get healthier",
        "Manage investments",
        "Share your expertise",
        "Different formats available",
        "Risk management",
        "Business motivation",
        "Team structure",
        "Current obstacles"
    ]
    
    let optionIcons: [String] = [
        "📊", "💼", "🏥", "💰", "📚", "🎨", "🔥", "💡", "👥", "⚠️"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background: dark gradient with a very subtle green wash so white cards and light-green accents feel cohesive
                LinearGradient(colors: [ModernDesign.Colors.gray900, ModernDesign.Colors.gray800], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                    .overlay(
                        Rectangle()
                            .fill(ModernDesign.Colors.success.opacity(0.04))
                            .blendMode(.overlay)
                    )
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header with back button and progress bar
                    HStack(spacing: 12) {
                        Button(action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "arrow.backward")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundStyle(ModernDesign.Colors.successLight)
                        }
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ModernDesign.Colors.gray700.opacity(0.25))
                                .frame(height: 6)

                            Capsule()
                                .fill(ModernDesign.Colors.successLight)
                                .frame(width: CGFloat(progress) * 240, height: 6)
                                .animation(.easeInOut(duration: 0.6), value: progress)
                        }
                        .frame(width: 240, height: 6)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    // Question bubble section
                    HStack(alignment: .top, spacing: 12) {
                        Image("duoReading")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)

                        // Bubble that sizes to its text content — now light green
                        Text(viewModel.question.text)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                            .background(
                                Capsule()
                                    .fill(ModernDesign.Colors.successLight)
                            )
                            .layoutPriority(1)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                    .animation(.easeInOut(duration: 0.4), value: index)
                    
                    // Title
                    Text("Choose your goal")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                    
                    // Answer cards
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(0..<viewModel.question.options.count, id: \.self) { i in
                                OptionCardView(
                                    question: $viewModel.question,
                                    selectedEntry: $selectedEntry,
                                    selectedIndex: i,
                                    optionText: viewModel.question.options[i],
                                    onSelect: { selectedValue in
                                        if let val = selectedValue {
                                            viewModel.answers[viewModel.question.id] = val
                                        } else {
                                            viewModel.answers[viewModel.question.id] = ""
                                        }
                                    }
                                )
                                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .animation(.easeInOut(duration: 0.4), value: index)
                    
                    // Continue button
                    VStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                if let saved = viewModel.answers[viewModel.question.id], !saved.isEmpty {
                                    viewModel.saveAnswer(saved)
                                } else if let sel = viewModel.question.selectedOption, !sel.isEmpty {
                                    viewModel.saveAnswer(sel)
                                }

                                if(index < StaticQuestions.questions.count - 1) {
                                    index = index + 1
                                    viewModel.getQuestionAtIndex(index: index)
                                    selectedEntry = Array(repeating: false, count: StaticQuestions.questions[index].options.count)

                                    if let prev = viewModel.answers[StaticQuestions.questions[index].id], !prev.isEmpty {
                                        let parts = prev.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                                        for i in 0..<StaticQuestions.questions[index].options.count {
                                            let opt = StaticQuestions.questions[index].options[i].lowercased()
                                            if parts.contains(opt) || parts.contains("other") && opt.contains("other") {
                                                selectedEntry[i] = true
                                            }
                                        }
                                        for i in 0..<StaticQuestions.questions[index].options.count {
                                            if StaticQuestions.questions[index].options[i].lowercased().contains("other") {
                                                viewModel.question.selectedOption = prev
                                            }
                                        }
                                    }

                                    progress = CGFloat(index + 1) / CGFloat(StaticQuestions.questions.count)
                                } else {
                                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                    self.presentationMode.wrappedValue.dismiss()
                                }
                            }
                        }) {
                            Text(index < StaticQuestions.questions.count - 1 ? "Continue" : "Complete")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(isEnableContinueButton() ? ModernDesign.Colors.success : Color.gray.opacity(0.3))
                                .clipShape(Capsule())
                        }
                        .disabled(!isEnableContinueButton())
                    }
                    .padding(20)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            selectedEntry = Array(repeating: false, count: viewModel.question.options.count)

            if let saved = viewModel.savedAnswerForCurrentQuestion(), !saved.isEmpty {
                let parts = saved.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                for i in 0..<viewModel.question.options.count {
                    let opt = viewModel.question.options[i].lowercased()
                    if parts.contains(opt) || (opt.contains("other") && !saved.isEmpty) {
                        selectedEntry[i] = true
                        if opt.contains("other") {
                            viewModel.question.selectedOption = saved
                        }
                    }
                }
            }
        }
    }
    
    func isEnableContinueButton() -> Bool {
        for i in 0..<selectedEntry.count {
            if(selectedEntry[i]) {
                return true
            }
        }
        return false
    }
}

#Preview {
    OnboardingQuestionaireView()
}
