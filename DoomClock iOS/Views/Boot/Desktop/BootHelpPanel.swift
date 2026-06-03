import SwiftUI

private extension String {
    /// Trims code-indentation from multiline help copy while preserving paragraph breaks.
    var helpPanelText: String {
        split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
    }
}

struct BootHelpPanel: View {
    let color: Color
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            helpTitleBar
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    helpSection(
                        title: "WHAT IS DOOMCLOCK?",
                        body: """
                        DoomClock is not a prediction system.

                        It does not know the future.
                        It does not determine endings.

                        It helps you observe what you learn
                        between the beginning of something
                        and its end.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "COUNTDOWN",
                        body: """
                        A countdown represents the expected
                        end of something.

                        The thing may be serious,
                        trivial, real, symbolic,
                        or completely fictional.

                        The lesson is what matters.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "THREAT LEVEL",
                        body: """
                        Threat Levels are symbolic.

                        They describe perspective,
                        not danger.

                        Example:

                        THE TEA IS STILL WARM

                        Meaning:
                        there is still time.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "THE REGISTRY",
                        body: """
                        The Registry records incidents,
                        lessons and endings.

                        Its existence has never been
                        officially confirmed.

                        This has not stopped anyone
                        from using it.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "ARCHIVE",
                        body: """
                        The Archive contains incidents
                        and lessons left behind.

                        Some are real.
                        Some are fictional.

                        The Archive makes no distinction.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "OPERATOR",
                        body: """
                        The person currently using
                        DoomClock OS.

                        Possibly you.
                        """.helpPanelText
                    )

                    helpSection(
                        title: "REMEMBER",
                        body: """
                        Time doesn't end things.

                        It reveals them.
                        """.helpPanelText
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)

            Button(action: onClose) {
                Text("[ CLOSE ]")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(color.opacity(0.06))
                            )
                    )
            }
            .buttonStyle(.plain)
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

    private var helpTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("HELP / OPERATOR MANUAL")
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

    private func helpSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.88))
            Text(body)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
