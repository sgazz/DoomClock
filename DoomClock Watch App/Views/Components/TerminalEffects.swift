import SwiftUI

struct TerminalFlickerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isStable = false

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion || isStable ? 1 : 0.75)
            .offset(x: reduceMotion || isStable ? 0 : -1)
            .onAppear {
                guard !reduceMotion else {
                    isStable = true
                    return
                }

                isStable = false
                withAnimation(.easeOut(duration: 0.35)) {
                    isStable = true
                }
            }
    }
}

struct TerminalPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let color: Color
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .shadow(color: isActive && !reduceMotion ? color.opacity(0.35) : .clear, radius: 3)
    }
}

extension View {
    func terminalFlicker() -> some View {
        modifier(TerminalFlickerModifier())
    }

    func terminalPulse(color: Color, isActive: Bool) -> some View {
        modifier(TerminalPulseModifier(color: color, isActive: isActive))
    }
}

