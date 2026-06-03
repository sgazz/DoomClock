import SwiftUI

struct TerminalProgressBar: View {
    let progress: Double
    let color: Color
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(color.opacity(0.35), lineWidth: 1)

                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(color.opacity(0.85))
                        .frame(width: max(geometry.size.width * progress, progress > 0 ? 4 : 0))
                        .shadow(color: color.opacity(0.4), radius: 2)
                }
            }
            .frame(height: 10)
        }
    }
}
