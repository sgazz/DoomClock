import SwiftUI

struct TerminalASCIIBlockView: View {
    let content: String
    let color: Color
    var pulseOnAppear: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(content)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.84))
                .shadow(color: color.opacity(0.22), radius: 1.5)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
        )
        .bootPulse(active: pulseOnAppear, color: color)
    }
}

private struct BootPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let active: Bool
    let color: Color

    @State private var glowAmount: Double = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowAmount * 0.45), radius: glowAmount * 9)
            .onAppear {
                guard active, !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    glowAmount = 1
                }
                withAnimation(.easeIn(duration: 0.16).delay(0.22)) {
                    glowAmount = 0
                }
            }
    }
}

private extension View {
    func bootPulse(active: Bool, color: Color) -> some View {
        modifier(BootPulseModifier(active: active, color: color))
    }
}
