import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel

    var body: some View {
        NavigationStack {
            if viewModel.settings.hasCompletedOnboarding {
                CountdownView()
            } else {
                OnboardingView()
            }
        }
    }
}
