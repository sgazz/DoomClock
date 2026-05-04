import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel

    var body: some View {
        NavigationStack {
            if viewModel.hasCompletedOnboarding {
                CountdownView()
            } else {
                OnboardingView()
            }
        }
    }
}
