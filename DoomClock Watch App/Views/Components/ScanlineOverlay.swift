import SwiftUI

struct ScanlineOverlay: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let lineHeight: CGFloat = 2
            let gap: CGFloat = 5
            var y: CGFloat = 0

            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: lineHeight)
                context.fill(Path(rect), with: .color(color.opacity(0.035)))
                y += gap
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
