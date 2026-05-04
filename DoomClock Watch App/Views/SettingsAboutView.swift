import SwiftUI

struct SettingsAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var isTransitioning = false

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("ABOUT")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(mode.primaryColor)
                        .lineLimit(1)

                    Text("DoomClock is a fictional personal countdown. It is not a prediction or warning system.")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(mode.primaryColor.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    TerminalButton(title: "RESET COUNTDOWN", color: mode.primaryColor) {
                        guard !isTransitioning else { return }
                        viewModel.resetCountdown()
                    }
                    .disabled(isTransitioning)
                    .opacity(isTransitioning ? 0.55 : 1)

                    TerminalButton(title: "RESET ONBOARDING", color: mode.primaryColor, isProminent: true) {
                        guard !isTransitioning else { return }
                        isTransitioning = true
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            viewModel.resetOnboarding()
                        }
                    }
                    .disabled(isTransitioning)
                    .opacity(isTransitioning ? 0.55 : 1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }

            ScanlineOverlay(color: mode.primaryColor)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
