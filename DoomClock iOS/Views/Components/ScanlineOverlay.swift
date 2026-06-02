import SwiftUI

struct ScanlineOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isDrifting = false

    var color: Color

    var body: some View {
        Canvas { context, size in
            let lineHeight: CGFloat = 2
            let gap: CGFloat = 5
            var y: CGFloat = 0

            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: lineHeight)
                context.fill(Path(rect), with: .color(color.opacity(0.08)))
                y += gap
            }
        }
        .opacity(0.8)
        .offset(y: reduceMotion ? 0 : (isDrifting ? 7 : 0))
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                isDrifting = true
            }
        }
    }
}
