import SwiftUI

struct CountdownNumberView: View {
    let value: Int
    let label: String
    let color: Color
    var minimumDigits = 2
    var numberSize: CGFloat = 21
    var labelSize: CGFloat = 9

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(String(format: "%0\(minimumDigits)d", value))
                .font(.system(size: numberSize, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .foregroundStyle(color)
                .monospacedDigit()

            Text(label)
                .font(.system(size: labelSize, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(color.opacity(0.68))
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
