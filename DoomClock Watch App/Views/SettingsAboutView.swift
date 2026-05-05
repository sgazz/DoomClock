import SwiftUI

struct SettingsAboutView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var isTransitioning = false

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: mode.primaryColor)

            VStack(spacing: 8) {
                DoomClockUI.title("ABOUT", color: mode.primaryColor)
                DoomClockUI.primaryText("Fictional countdown only.", color: mode.primaryColor)

                DoomClockUI.primaryButton(title: "RESET COUNTDOWN", color: mode.primaryColor, isDisabled: isTransitioning) {
                    guard !isTransitioning else { return }
                    isTransitioning = true
                    viewModel.resetCountdown()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isTransitioning = false
                    }
                }

                DoomClockUI.secondaryButton(title: "RESET ONBOARDING", color: mode.primaryColor, isDisabled: isTransitioning) {
                    guard !isTransitioning else { return }
                    isTransitioning = true
                    viewModel.resetOnboarding()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
