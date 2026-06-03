import SwiftUI

struct CRTShutdownOverlay: View {
    let stage: ShutdownStage
    let color: Color
    let dotOpacity: Double

    var body: some View {
        ZStack {
            Color.black
                .opacity(stage == .black ? 1 : 0)
                .animation(.easeOut(duration: 0.55), value: stage)

            if stage == .line || stage == .dot {
                shutdownBeam
                    .shadow(color: color.opacity(0.85), radius: stage == .line ? 10 : 4)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private var shutdownBeam: some View {
        if stage == .line {
            Capsule()
                .fill(color.opacity(0.95))
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        } else {
            Circle()
                .fill(color.opacity(0.92))
                .frame(width: 6, height: 6)
                .opacity(dotOpacity)
        }
    }
}
