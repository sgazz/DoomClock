import SwiftUI

struct BootNewCountdownPanel: View {
    let color: Color
    @Binding var title: String
    @Binding var matter: String
    var focusedField: FocusState<NewCountdownField?>.Binding
    let onContinue: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelTitleBar
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(
                        """
                        DoomClock does not predict the end.
                        It helps you observe what you learn before something ends.
                        """
                    )
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                    Text("What is ending?")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.88))

                    TerminalInputLine(
                        label: "Title:",
                        text: $title,
                        field: .title,
                        focusedField: focusedField,
                        isInteractive: true,
                        isLastInForm: false,
                        color: color,
                        onSubmit: onContinue,
                        onNext: { focusedField.wrappedValue = .matter }
                    )

                    Text("Optional:")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.52))
                        .padding(.top, 2)

                    TerminalInputLine(
                        label: "Why does it matter?",
                        text: $matter,
                        field: .matter,
                        focusedField: focusedField,
                        isInteractive: true,
                        isLastInForm: true,
                        color: color,
                        onSubmit: onContinue,
                        onNext: { focusedField.wrappedValue = .matter }
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)

            HStack(spacing: 10) {
                panelActionButton(title: "[ CONTINUE ]", prominent: true, action: onContinue)
                panelActionButton(title: "[ CLOSE ]", prominent: false, action: onClose)
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

    private var panelTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("NEW COUNTDOWN / DEFINE THE END")
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

    private func panelActionButton(title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
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
