//
//  OnboardingViewModel.swift
//  businessapp
//
//  Created by Євген Жадан on 07.11.2025.
//

import Foundation
import Combine

class OnboardingViewModel: ObservableObject {
    @Published var question: Question
    var index: Int

    init(){
        // use the first static question as a sensible default if available
        question = StaticQuestions.questions.first ?? Question(id: UUID().uuidString, text: "", options: [])
        index = 0
        self.getQuestionAtIndex(index: index)
    }

    func getQuestionAtIndex(index: Int) {
        if index < StaticQuestions.questions.count {
            question = StaticQuestions.questions[index]
        }
    }
}