import SwiftUI

struct CountdownView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 15) {
                    header

                    if viewModel.isExpired {
                        expiredContent
                    } else {
                        countdownContent
                    }

                    controls
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }

            ScanlineOverlay(color: mode.primaryColor)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private var header: some View {
        VStack(spacing: 5) {
            Text("D-DAY IN")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.75))
                .lineLimit(1)

            Text(mode.statusText)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(mode.accentColor.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var countdownContent: some View {
        let remaining = viewModel.remainingComponents

        return VStack(spacing: 12) {
            countdownCard(for: remaining)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.3), lineWidth: 1)
            )

            Text(targetDateText)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
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
                CountdownNumberView(value: remaining.seconds, label: "s", color: mode.primaryColor)
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .frame(maxWidth: .infinity)
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
                    controlLabel("SET DOOMSDAY")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.black)
                .background(buttonBackground(fillOpacity: 0.92, strokeOpacity: 0.95))
            }

            HStack(spacing: 7) {
                if viewModel.hasTargetDate && viewModel.canEditDoomsday {
                    NavigationLink {
                        EditDoomsdayView()
                    } label: {
                        controlLabel("EDIT")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.black)
                    .background(buttonBackground(fillOpacity: 0.92, strokeOpacity: 0.95))
                }

                NavigationLink {
                    DoomModeView()
                } label: {
                    controlLabel("MODE")
                }
                .buttonStyle(.plain)
                .foregroundStyle(mode.primaryColor)
                .background(buttonBackground(fillOpacity: 0.08, strokeOpacity: 0.52))

                NavigationLink {
                    SettingsAboutView()
                } label: {
                    controlLabel("INFO")
                }
                .buttonStyle(.plain)
                .foregroundStyle(mode.primaryColor.opacity(0.62))
                .background(buttonBackground(fillOpacity: 0.04, strokeOpacity: 0.28))
            }
        }
    }

    private func controlLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced).weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }

    private func buttonBackground(fillOpacity: Double, strokeOpacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(mode.primaryColor.opacity(fillOpacity))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(mode.primaryColor.opacity(strokeOpacity), lineWidth: 1)
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
