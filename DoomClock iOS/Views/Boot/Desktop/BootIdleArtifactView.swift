import SwiftUI

struct BootIdleArtifactView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let text: String
    let color: Color

    @State private var opacity: Double = 0

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.58))
            .shadow(color: color.opacity(0.16), radius: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(opacity)
            .onAppear {
                if reduceMotion {
                    opacity = 1
                } else {
                    withAnimation(.easeIn(duration: 0.28)) {
                        opacity = 1
                    }
                }
            }
    }
}
