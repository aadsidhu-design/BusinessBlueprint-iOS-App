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
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                HStack {
                    Button(action: {  // Dismiss button
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.backward")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .foregroundStyle(.gray)
                    }
                    .padding()
                    
                    ZStack(alignment: .leading) {  // Progress bar
                        Rectangle()
                            .foregroundStyle(.gray.opacity(0.3))
                            .frame(width: 300, height: 20)
                        
                        Rectangle()
                            .foregroundStyle(.green)
                            .frame(width: CGFloat(progress) * 300, height: 20)
                            .clipShape(.rect(cornerRadius: 10))
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                    .clipShape(.rect(cornerRadius: 10))
                }
                
                HStack {
                    Image("duoReading")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    
                    ZStack {
                        SpeechBubble(cornerRadius: 20, isBottom: false, pointLocation: 20)
                            .fill(.green)
                        
                        Text(viewModel.question.text)  // Question
                            .font(.system(size: 20))
                            .bold()
                            .foregroundStyle(.white)
                            .padding()
                    }
                    .frame(width: 200, height: 100)
                    .padding()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .animation(.easeInOut(duration: 0.4), value: index)
                
                if index == 0 {
                    Text("Choose your goal")
                        .font(.system(size: 25))
                        .bold()
                        .foregroundStyle(.black)
                        .padding()
                }
                
                ScrollView {  // Answer cards
                    LazyVStack {
                        ForEach(0..<viewModel.question.options.count, id: \.self) { i in
                            SelectionCardView(
                                question: $viewModel.question,
                                selectedEntry: $selectedEntry,
                                queryIndex: index,
                                selectedIndex: i,
                                onSelect: { selectedValue in
                                    // Persist selection into viewModel.answers
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
                }
                .animation(.easeInOut(duration: 0.4), value: index)
                
                Spacer()
                
                Button(action: {  // Continue Button
                    withAnimation(.easeInOut(duration: 0.4)) {
                        // ensure current question's answer is saved if there is a selection
                        if let saved = viewModel.answers[viewModel.question.id], !saved.isEmpty {
                            viewModel.saveAnswer(saved)
                        } else if let sel = viewModel.question.selectedOption, !sel.isEmpty {
                            viewModel.saveAnswer(sel)
                        }

                        if(index < StaticQuestions.questions.count - 1) {
                        index = index + 1
                        viewModel.getQuestionAtIndex(index: index)

                        // Initialize selectedEntry array for new question
                        selectedEntry = Array(repeating: false, count: StaticQuestions.questions[index].options.count)

                        // If we already have an answer for this question, pre-select entries
                        if let prev = viewModel.answers[StaticQuestions.questions[index].id], !prev.isEmpty {
                            // For multiple answers stored as comma-separated, mark matching options
                            let parts = prev.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                            for i in 0..<StaticQuestions.questions[index].options.count {
                                let opt = StaticQuestions.questions[index].options[i].lowercased()
                                if parts.contains(opt) || parts.contains("other") && opt.contains("other") {
                                    selectedEntry[i] = true
                                }
                            }
                            // put saved custom text into question.selectedOption if option was Other
                            for i in 0..<StaticQuestions.questions[index].options.count {
                                if StaticQuestions.questions[index].options[i].lowercased().contains("other") {
                                    viewModel.question.selectedOption = prev
                                }
                            }
                        }

                        progress = CGFloat(index + 1) / CGFloat(StaticQuestions.questions.count)
                        } else {
                            // Complete onboarding
                            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }
                }) {
                    Text(index < StaticQuestions.questions.count - 1 ? "Continue" : "Complete")
                        .font(.system(size: 20))
                        .bold()
                        .foregroundStyle(.white)
                        .padding(EdgeInsets(top: 16, leading: 100, bottom: 16, trailing: 100))
                        .background(isEnableContinueButton() ? .green : .gray)
                        .clipShape(.rect(cornerRadius: 10))
                }
                .padding(.leading, 50)
                .disabled(!isEnableContinueButton())
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Initialize selectedEntry for first question
            selectedEntry = Array(repeating: false, count: viewModel.question.options.count)

            // If we have a previously saved answer, pre-select
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
