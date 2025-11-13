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
                            SelectionCardView(question: $viewModel.question, selectedEntry: $selectedEntry, queryIndex: index, selectedIndex: i)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {  // Continue Button
                    if(index < StaticQuestions.questions.count - 1) {
                        index = index + 1
                        viewModel.getQuestionAtIndex(index: index)
                        
                        // Initialize selectedEntry array for new question
                        selectedEntry = Array(repeating: false, count: StaticQuestions.questions[index].options.count)
                        
                        progress = CGFloat(index + 1) / CGFloat(StaticQuestions.questions.count)
                    } else {
                        // Complete onboarding
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        self.presentationMode.wrappedValue.dismiss()
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
