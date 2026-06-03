import SwiftUI

struct BootFlashOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let color: Color
    let trigger: Int

    @State private var flashAmount: Double = 0

    var body: some View {
        ZStack {
            color.opacity(0.035 * flashAmount)
            Color.orange.opacity(0.028 * flashAmount)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            playFlash()
        }
    }

    private func playFlash() {
        guard !reduceMotion else { return }
        flashAmount = 1
        withAnimation(.easeOut(duration: 0.07)) {
            flashAmount = 0.55
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashAmount = 0
            }
        }
    }
}
