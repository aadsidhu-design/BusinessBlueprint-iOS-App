import SwiftUI

struct CoachHubView: View {
    @ObservedObject var timelineVM: IslandTimelineViewModel
    
    var body: some View {
        EnhancedCoachView(timelineVM: timelineVM)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CoachHubView(timelineVM: IslandTimelineViewModel())
    }
}
