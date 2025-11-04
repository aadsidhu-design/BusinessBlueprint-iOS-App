import SwiftUI

struct RootView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var businessPlanStore: BusinessPlanStore
    
    var body: some View {
        Group {
            if businessPlanStore.quizCompleted {
                MainTabView()
            } else {
                QuizView()
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
