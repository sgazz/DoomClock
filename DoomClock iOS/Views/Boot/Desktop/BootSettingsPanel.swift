import SwiftUI

struct BootSettingsPanel: View {
    let color: Color
    let operatorNameDisplay: String
    let purposeDisplay: String
    let reduceMotionActive: Bool
    @Binding var alwaysShowBootSequence: Bool
    @Binding var enableCRTEffects: Bool
    @Binding var enableBootAnimations: Bool
    @Binding var enableSounds: Bool
    @Binding var enableHaptics: Bool
    @Binding var showIncidentFeed: Bool
    @Binding var showDailyIncident: Bool
    @Binding var soundVolume: Double
    let onClose: () -> Void
    let onClearIdentity: () -> Void
    let onToggleFeedback: () -> Void
    let onTestSound: () -> Void
    let onTestCrtShutdown: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsTitleBar
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    operatorSection
                        .padding(.bottom, 18)

                    systemSection
                        .padding(.bottom, 18)

                    soundsSection
                        .padding(.bottom, 18)

                    experienceSection
                        .padding(.bottom, 18)

                    archiveSection
                        .padding(.bottom, 18)

                    aboutSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 360)

            HStack(spacing: 10) {
                settingsActionButton(title: "[ CLOSE ]", prominent: true, action: onClose)
                settingsActionButton(title: "[ CLEAR OPERATOR IDENTITY ]", prominent: false, action: onClearIdentity)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.black.opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: color.opacity(0.32), radius: 10, y: 2)
        .shadow(color: color.opacity(0.14), radius: 3, y: 0)
    }

    private var operatorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ OPERATOR ]")
            settingsInfoRow(label: "NAME:", value: operatorNameDisplay)
            settingsInfoRow(label: "PURPOSE:", value: purposeDisplay)
        }
    }

    private var systemSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ SYSTEM ]")

            settingsToggleRow(
                label: "ALWAYS SHOW BOOT SEQUENCE",
                isOn: alwaysShowBootSequence
            ) {
                alwaysShowBootSequence.toggle()
                onToggleFeedback()
            }

            settingsToggleRow(
                label: "CRT EFFECTS",
                isOn: enableCRTEffects
            ) {
                enableCRTEffects.toggle()
                onToggleFeedback()
            }

            settingsToggleRow(
                label: "BOOT ANIMATIONS",
                isOn: enableBootAnimations
            ) {
                enableBootAnimations.toggle()
                onToggleFeedback()
            }

            settingsToggleRow(
                label: "HAPTICS",
                isOn: enableHaptics
            ) {
                enableHaptics.toggle()
                onToggleFeedback()
            }

            settingsInfoRow(
                label: "REDUCE MOTION:",
                value: reduceMotionActive ? "SYSTEM ACTIVE" : "SYSTEM CONTROLLED"
            )
        }
    }

    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ SOUNDS ]")

            settingsToggleRow(
                label: "SOUNDS ENABLED",
                isOn: enableSounds
            ) {
                enableSounds.toggle()
                onToggleFeedback()
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text("SOUND VOLUME:")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.52))
                    Spacer(minLength: 8)
                    Text("\(Int((soundVolume * 100).rounded()))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.82))
                }

                Slider(value: $soundVolume, in: 0...1)
                    .tint(color.opacity(0.72))
                    .disabled(!enableSounds)
                    .opacity(enableSounds ? 1 : 0.45)
            }

            settingsActionButton(title: "[ TEST SOUND ]", prominent: false, action: onTestSound)
            settingsActionButton(title: "[ TEST CRT SHUTDOWN ]", prominent: false, action: onTestCrtShutdown)
        }
    }

    private var experienceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ EXPERIENCE ]")

            settingsToggleRow(
                label: "SHOW INCIDENT FEED",
                isOn: showIncidentFeed
            ) {
                showIncidentFeed.toggle()
                onToggleFeedback()
            }

            settingsToggleRow(
                label: "RECEIVE INCIDENT OF THE DAY",
                isOn: showDailyIncident
            ) {
                showDailyIncident.toggle()
                onToggleFeedback()
            }
        }
    }

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ ARCHIVE ]")
            settingsInfoRow(label: "ARCHIVE ACCESS:", value: "LOCAL ONLY")
            settingsInfoRow(label: "DATA STORAGE:", value: "THIS DEVICE")
            settingsInfoRow(label: "REGISTRY LINK:", value: "UNRESOLVED")
            settingsInfoRow(label: "ARCHIVE CYCLE:", value: "7342")
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            settingsSectionHeader("[ ABOUT ]")
            settingsInfoRow(label: "DOOMCLOCK OS:", value: "∆7342.11")
            settingsInfoRow(label: "REGISTRY REVISION:", value: "UNRESOLVED")
            settingsInfoRow(label: "BUILD:", value: "7342")
        }
    }

    private var settingsTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("SYSTEM SETTINGS / OPERATOR PROFILE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.94))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text("[ ACTIVE WINDOW ]")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Rectangle()
                .fill(color.opacity(0.22))
                .frame(height: 1)
        }
    }

    private func settingsSectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.88))
                .shadow(color: color.opacity(0.18), radius: 1)

            Rectangle()
                .fill(color.opacity(0.14))
                .frame(height: 1)
        }
        .padding(.bottom, 2)
    }

    private func settingsInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.52))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsToggleRow(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("[ \(isOn ? "X" : " ") ]")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(isOn ? 0.92 : 0.48))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func settingsActionButton(title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: prominent ? .bold : .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(prominent ? 0.92 : 0.62))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(color.opacity(prominent ? 0.5 : 0.32), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(color.opacity(prominent ? 0.06 : 0.03))
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
