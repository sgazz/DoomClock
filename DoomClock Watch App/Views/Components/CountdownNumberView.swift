import SwiftUI

struct CountdownNumberView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTicking = false

    let value: Int
    let label: String
    let color: Color
    var minimumDigits = 2
    var numberSize: CGFloat = 21
    var labelSize: CGFloat = 9
    var animatesTick = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(String(format: "%0\(minimumDigits)d", value))
                .font(.system(size: numberSize, weight: .bold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
                .foregroundStyle(color)
                .monospacedDigit()
                .opacity(animatesTick ? (isTicking ? 1 : 0.88) : 1)
                .offset(x: animatesTick && isTicking && !reduceMotion ? 1 : 0)
                .shadow(color: animatesTick && isTicking && !reduceMotion ? color.opacity(0.45) : .clear, radius: 3)

            Text(label)
                .font(.system(size: labelSize, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .foregroundStyle(color.opacity(0.68))
        }
        .fixedSize(horizontal: false, vertical: true)
        .onChange(of: value) { _, _ in
            guard animatesTick, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.06)) {
                isTicking = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.06)) {
                    isTicking = false
                }
            }
        }
    }
}
