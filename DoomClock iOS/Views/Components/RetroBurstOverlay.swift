import SwiftUI

struct RetroBurstOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    private let particles: [RetroBurstParticle] = [
        .init(base: CGSize(width: -44, height: -10), travel: CGSize(width: -18, height: -24), rotation: -18, color: .terminalGreen),
        .init(base: CGSize(width: -30, height: -30), travel: CGSize(width: -16, height: -20), rotation: 24, color: .terminalYellow),
        .init(base: CGSize(width: -12, height: -40), travel: CGSize(width: -8, height: -24), rotation: -8, color: .terminalOrange),
        .init(base: CGSize(width: 12, height: -40), travel: CGSize(width: 8, height: -24), rotation: 8, color: .terminalGreen),
        .init(base: CGSize(width: 30, height: -30), travel: CGSize(width: 16, height: -20), rotation: -24, color: .terminalRed),
        .init(base: CGSize(width: 44, height: -10), travel: CGSize(width: 18, height: -24), rotation: 18, color: .terminalOrange),
        .init(base: CGSize(width: -48, height: 12), travel: CGSize(width: -20, height: 10), rotation: 72, color: .terminalYellow),
        .init(base: CGSize(width: 48, height: 12), travel: CGSize(width: 20, height: 10), rotation: -72, color: .terminalGreen),
        .init(base: CGSize(width: -34, height: 28), travel: CGSize(width: -18, height: 18), rotation: 42, color: .terminalRed),
        .init(base: CGSize(width: 34, height: 28), travel: CGSize(width: 18, height: 18), rotation: -42, color: .terminalYellow),
        .init(base: CGSize(width: -14, height: 38), travel: CGSize(width: -8, height: 20), rotation: -36, color: .terminalGreen),
        .init(base: CGSize(width: 14, height: 38), travel: CGSize(width: 8, height: 20), rotation: 36, color: .terminalOrange),
        .init(base: CGSize(width: 0, height: -48), travel: CGSize(width: 0, height: -20), rotation: 0, color: .terminalYellow),
        .init(base: CGSize(width: -58, height: 0), travel: CGSize(width: -14, height: -4), rotation: 90, color: .terminalGreen),
        .init(base: CGSize(width: 58, height: 0), travel: CGSize(width: 14, height: -4), rotation: 90, color: .terminalRed)
    ]

    var body: some View {
        ZStack {
            if reduceMotion {
                Circle()
                    .stroke(Color.terminalGreen.opacity(0.18), lineWidth: 1)
                    .frame(width: 124, height: 124)
                    .blur(radius: 1.5)
            } else {
                ForEach(Array(particles.enumerated()), id: \.offset) { index, particle in
                    particleView(particle, index: index)
                }
            }
        }
        .frame(width: 160, height: 136)
        .allowsHitTesting(false)
        .onAppear {
            guard !reduceMotion else { return }
            isExpanded = false
            withAnimation(.easeOut(duration: 1.2)) {
                isExpanded = true
            }
        }
    }

    private func particleView(_ particle: RetroBurstParticle, index: Int) -> some View {
        Capsule()
            .fill(particle.color)
            .frame(width: index.isMultiple(of: 3) ? 4 : 3, height: index.isMultiple(of: 2) ? 10 : 7)
            .shadow(color: particle.color.opacity(isExpanded ? 0 : 0.35), radius: 2)
            .rotationEffect(.degrees(particle.rotation))
            .offset(
                x: particle.base.width + (isExpanded ? particle.travel.width : 0),
                y: particle.base.height + (isExpanded ? particle.travel.height : 0)
            )
            .opacity(isExpanded ? 0 : 0.92)
            .scaleEffect(isExpanded ? 0.55 : 1)
    }
}

private struct RetroBurstParticle {
    let base: CGSize
    let travel: CGSize
    let rotation: Double
    let color: Color
}

private extension Color {
    static let terminalGreen = Color(red: 0.71, green: 1.0, blue: 0.48)
    static let terminalYellow = Color(red: 0.91, green: 1.0, blue: 0.44)
    static let terminalOrange = Color(red: 1.0, green: 0.72, blue: 0.30)
    static let terminalRed = Color(red: 1.0, green: 0.29, blue: 0.24)
}
