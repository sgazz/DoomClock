import SwiftUI

struct BootDashboardPanel<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.88))
                .shadow(color: color.opacity(0.22), radius: 1)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
        )
    }
}
