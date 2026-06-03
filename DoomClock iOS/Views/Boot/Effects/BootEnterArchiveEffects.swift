import SwiftUI

struct BootEnterArchivePulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let color: Color

    @State private var pulseAmount: Double = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.18 + pulseAmount * 0.22), radius: 2 + pulseAmount * 2.5)
            .opacity(0.9 + pulseAmount * 0.1)
            .onAppear {
                updatePulse()
            }
            .onChange(of: isActive) { _, _ in
                updatePulse()
            }
    }

    private func updatePulse() {
        guard isActive, !reduceMotion else {
            pulseAmount = 0
            return
        }

        pulseAmount = 0
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
            pulseAmount = 1
        }
    }
}
