import SwiftUI

private struct BootDashboardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct BootDashboardView: View {
    let color: Color
    var isDesktopActionsEnabled: Bool = false
    let onNewCountdown: () -> Void
    let onHelp: () -> Void
    let onSettings: () -> Void
    let onLogout: () -> Void

    @State private var containerWidth: CGFloat = 0

    private var useSideBySide: Bool {
        containerWidth >= 600
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if useSideBySide {
                    HStack(alignment: .top, spacing: 10) {
                        dashboardPanels
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        dashboardPanels
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: BootDashboardWidthKey.self, value: geometry.size.width)
                }
            )
            .onPreferenceChange(BootDashboardWidthKey.self) { width in
                containerWidth = width
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DOOMCLOCK OS ∆7342.11")
                Text("Registry Revision: UNRESOLVED")
                Text("Archive Cycle 7342")
                Text("Some endings reserved.")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.46))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var dashboardPanels: some View {
        BootDashboardPanel(title: "FINAL STATE (LOOP)", color: color) {
            VStack(alignment: .leading, spacing: 4) {
                dashboardNewCountdownItem
                dashboardMenuItem("> ACTIVE COUNTDOWNS")
                dashboardMenuItem("> ARCHIVE BROWSER")
                dashboardMenuItem("> INCIDENT OF THE DAY")
                dashboardHelpItem
                dashboardSettingsItem
                dashboardLogoutItem
            }
        }

        BootDashboardPanel(title: "STATUS", color: color) {
            VStack(alignment: .leading, spacing: 5) {
                statusRow(label: "Archive Cycle:", value: "7342")
                statusRow(label: "Active Countdowns:", value: "1")
                statusRow(label: "Archived Incidents:", value: "7,342")
                statusRow(label: "Lessons Learned:", value: "2,104")
                statusRow(label: "Threat Level:", value: "THE TEA IS STILL WARM")
                statusRow(label: "System Integrity:", value: "STABLE")
                statusRow(label: "Registry Connection:", value: "SECURE", trailing: "★★★★")
            }
        }

        BootDashboardPanel(title: "SYSTEM FEED", color: color) {
            VStack(alignment: .leading, spacing: 10) {
                feedEntry(
                    headline: "> Someone activated DoomClock",
                    detail: "  12 seconds ago."
                )
                feedEntry(
                    headline: "> A lesson was learned",
                    detail: "  somewhere."
                )
                feedEntry(
                    headline: "> The day continued",
                    detail: "  without asking permission."
                )
                Text("> As expected.")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
            }
        }
    }

    private var dashboardNewCountdownItem: some View {
        Button(action: onNewCountdown) {
            Text("> NEW COUNTDOWN")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isDesktopActionsEnabled ? 0.98 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isDesktopActionsEnabled)
    }

    private var dashboardHelpItem: some View {
        Button(action: onHelp) {
            Text("> HELP")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isDesktopActionsEnabled ? 0.72 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isDesktopActionsEnabled)
    }

    private var dashboardSettingsItem: some View {
        Button(action: onSettings) {
            Text("> SETTINGS")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isDesktopActionsEnabled ? 0.72 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isDesktopActionsEnabled)
    }

    private var dashboardLogoutItem: some View {
        Button(action: onLogout) {
            Text("> LOGOUT")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isDesktopActionsEnabled ? 0.72 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isDesktopActionsEnabled)
    }

    private func dashboardMenuItem(_ text: String, highlighted: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 11, weight: highlighted ? .bold : .medium, design: .monospaced))
            .foregroundStyle(color.opacity(highlighted ? 0.98 : 0.62))
            .shadow(color: highlighted ? color.opacity(0.28) : .clear, radius: 1.5)
            .padding(.horizontal, highlighted ? 6 : 0)
            .padding(.vertical, highlighted ? 3 : 0)
            .background(
                highlighted
                    ? RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(color.opacity(0.22), lineWidth: 1)
                        )
                    : nil
            )
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusRow(label: String, value: String, trailing: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(color.opacity(0.58))
            if let trailing {
                Text(value)
                    .foregroundStyle(color.opacity(0.78))
                Spacer(minLength: 4)
                Text(trailing)
                    .foregroundStyle(color.opacity(0.72))
            } else {
                Text(value)
                    .foregroundStyle(color.opacity(0.78))
            }
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feedEntry(headline: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.82))
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.52))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
