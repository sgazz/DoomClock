import SwiftUI

struct BlinkingCursorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = true

    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.opacity(isVisible ? 0.95 : 0.15))
            .frame(width: 9, height: 15)
            .shadow(color: color.opacity(0.35), radius: 2)
            .onAppear {
                guard !reduceMotion else {
                    isVisible = true
                    return
                }

                isVisible = true
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
