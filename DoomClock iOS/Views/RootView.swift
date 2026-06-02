import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var hasCompletedBootSequence = false

    var body: some View {
        NavigationStack {
            if !hasCompletedBootSequence {
                BootSequenceView {
                    hasCompletedBootSequence = true
                }
            } else if viewModel.settings.hasCompletedOnboarding {
                CountdownView()
            } else {
                OnboardingView()
            }
        }
    }
}
