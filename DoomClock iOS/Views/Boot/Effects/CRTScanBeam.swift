import SwiftUI

/// CRT scan band: one full-screen sweep every `cycleDuration`, then idle until the next cycle.
struct CRTScanBeam: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let color: Color

    private static let cycleDuration: TimeInterval = 10
    private static let sweepDuration: TimeInterval = 3.4
    private static var sweepPortion: Double { sweepDuration / cycleDuration }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let cycleTime = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: Self.cycleDuration)
                let cyclePhase = cycleTime / Self.cycleDuration

                if cyclePhase < Self.sweepPortion, geometry.size.height > 0 {
                    let sweepProgress = cyclePhase / Self.sweepPortion
                    let envelope = sin(sweepProgress * .pi)
                    let beamHeight = max(geometry.size.height * 0.14, 40)
                    let travel = geometry.size.height + beamHeight
                    let y = sweepProgress * travel - beamHeight * 0.5

                    LinearGradient(
                        colors: [
                            color.opacity(0),
                            color.opacity(0.06 * envelope),
                            color.opacity(0.14 * envelope),
                            color.opacity(0.06 * envelope),
                            color.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geometry.size.width, height: beamHeight)
                    .offset(y: y)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
