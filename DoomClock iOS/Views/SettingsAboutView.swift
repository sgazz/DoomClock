import SwiftUI

struct SettingsAboutView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var isTransitioning = false
    @State private var showsResetConfirmation = false

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: mode.primaryColor)

            ScrollView {
                VStack(spacing: 18) {
                    Text("ABOUT TIME")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(mode.primaryColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.72)
                        .terminalFlicker()

                    Text("""
                    Time remaining.
                    More or less.
                    """)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(mode.primaryColor.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity)

                    Text("↓")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(mode.primaryColor)
                        .opacity(0.5)

                    Text("""
                    Time is,
                    as one wise person
                    said,

                    nature’s way
                    of keeping everything
                    from happening
                    all at once.

                    This app disagrees

                    and is actively
                    working to make
                    everything happen
                    exactly then.
                    """)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(mode.primaryColor.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity)

                    if showsResetConfirmation {
                        resetConfirmationPanel
                    } else {
                        dangerousButton(title: "RESET EVERYTHING") {
                            guard !isTransitioning else { return }
                            showsResetConfirmation = true
                        }
                    }

                    DoomClockUI.primaryButton(title: "BACK", color: mode.primaryColor, isDisabled: isTransitioning) {
                        guard !isTransitioning else { return }
                        isTransitioning = true
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private var resetConfirmationPanel: some View {
        VStack(spacing: 12) {
            Text("RESET DOOMCLOCK?")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.accentColor)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Text("""
            This will clear your countdown
            and restart setup.
            """)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.76))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                DoomClockUI.secondaryButton(title: "CANCEL", color: mode.primaryColor, isDisabled: isTransitioning) {
                    guard !isTransitioning else { return }
                    showsResetConfirmation = false
                }

                dangerousButton(title: "RESET") {
                    guard !isTransitioning else { return }
                    isTransitioning = true
                    viewModel.resetOnboarding()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.22))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(mode.accentColor.opacity(0.5), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private func dangerousButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            DoomSoundService.play(.buttonTap)
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(mode.accentColor.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(mode.accentColor.opacity(0.65), lineWidth: 1)
                        .allowsHitTesting(false)
                )
        }
        .buttonStyle(.plain)
        .opacity(isTransitioning ? 0.55 : 1)
        .disabled(isTransitioning)
    }
}
