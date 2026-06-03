import SwiftUI

struct BootSettingsPanel: View {
    let color: Color
    let operatorNameDisplay: String
    let purposeDisplay: String
    let reduceMotionActive: Bool
    @Binding var alwaysShowBootSequence: Bool
    @Binding var enableCRTEffects: Bool
    let onClose: () -> Void
    let onClearIdentity: () -> Void
    let onToggleHaptic: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsTitleBar
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    settingsInfoRow(label: "OPERATOR NAME:", value: operatorNameDisplay)
                    settingsInfoRow(label: "PURPOSE:", value: purposeDisplay)

                    settingsToggleRow(
                        label: "ALWAYS SHOW BOOT SEQUENCE",
                        isOn: alwaysShowBootSequence
                    ) {
                        alwaysShowBootSequence.toggle()
                        onToggleHaptic()
                    }

                    settingsToggleRow(
                        label: "CRT EFFECTS",
                        isOn: enableCRTEffects
                    ) {
                        enableCRTEffects.toggle()
                        onToggleHaptic()
                    }

                    settingsInfoRow(
                        label: "REDUCE MOTION:",
                        value: reduceMotionActive ? "SYSTEM ACTIVE" : "SYSTEM CONTROLLED"
                    )
                    settingsInfoRow(label: "ARCHIVE ACCESS:", value: "LOCAL ONLY")
                    settingsInfoRow(label: "REGISTRY LINK:", value: "UNVERIFIED")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)

            HStack(spacing: 10) {
                settingsActionButton(title: "[ CLOSE ]", prominent: true, action: onClose)
                settingsActionButton(title: "[ CLEAR IDENTITY ]", prominent: false, action: onClearIdentity)
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

    private var settingsTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("SETTINGS / OPERATOR PREFERENCES")
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
