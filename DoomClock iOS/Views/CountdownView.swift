import SwiftUI

struct CountdownView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: mode.primaryColor)

            VStack(spacing: 10) {
                header

                if viewModel.isExpired {
                    expiredContent
                } else {
                    countdownContent
                }

                controls
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private var header: some View {
        Text("THE END IN")
            .font(.system(size: 17, weight: .semibold, design: .monospaced))
            .foregroundStyle(mode.primaryColor)
            .lineLimit(1)
            .terminalFlicker()
    }

    private var countdownContent: some View {
        let remaining = viewModel.remainingComponents

        return VStack(spacing: 6) {
            countdownCard(for: remaining)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.3), lineWidth: 1)
                    .allowsHitTesting(false)
            )

            Text(targetDateText)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
    }

    private func countdownCard(for remaining: CountdownViewModel.RemainingTime) -> some View {
        VStack(spacing: remaining.days > 0 ? 6 : 0) {
            if remaining.days > 0 {
                HStack {
                    Spacer(minLength: 0)
                    CountdownNumberView(
                        value: remaining.days,
                        label: "d",
                        color: mode.primaryColor,
                        minimumDigits: 1,
                        numberSize: 24,
                        labelSize: 10
                    )
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
            }

            HStack(spacing: 10) {
                CountdownNumberView(value: remaining.hours, label: "h", color: mode.primaryColor)
                    .frame(maxWidth: .infinity)
                CountdownNumberView(value: remaining.minutes, label: "m", color: mode.primaryColor)
                    .frame(maxWidth: .infinity)
                CountdownNumberView(value: remaining.seconds, label: "s", color: mode.primaryColor, animatesTick: true)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .frame(maxWidth: .infinity)
        .terminalFlicker()
    }

    private var expiredContent: some View {
        VStack(spacing: 16) {
            Text("EVENT PASSED")
                .font(.system(.title3, design: .monospaced).weight(.bold))
                .foregroundStyle(mode.accentColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            countdownContent
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if !viewModel.hasTargetDate {
                NavigationLink {
                    EditDoomsdayView()
                } label: {
                    primaryControlLabel("SET DOOMSDAY")
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 7) {
                if viewModel.hasTargetDate && viewModel.canEditDoomsday {
                    NavigationLink {
                        EditDoomsdayView()
                    } label: {
                        primaryControlLabel("EDIT")
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    DoomModeView()
                } label: {
                    secondaryControlLabel("MODE", opacity: 1)
                }
                .buttonStyle(.plain)

                NavigationLink {
                    SettingsAboutView()
                } label: {
                    secondaryControlLabel("INFO", opacity: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func primaryControlLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(mode.primaryColor)
            )
    }

    private func secondaryControlLabel(_ text: String, opacity: Double) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(mode.primaryColor.opacity(opacity))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(mode.primaryColor.opacity(opacity * 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(mode.primaryColor.opacity(opacity * 0.5), lineWidth: 1)
                    .allowsHitTesting(false)
            )
    }

    private var targetDateText: String {
        guard let targetDate = viewModel.settings.targetDate else {
            return "NO DOOMSDAY SET"
        }

        return targetDate.formatted(
            .dateTime.month(.abbreviated).day().hour().minute()
        )
        .uppercased()
    }
}
