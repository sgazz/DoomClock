import SwiftUI

struct CRTPowerOnOverlay: View {
    let stage: PowerOnStage
    let color: Color
    let dotPulseScale: CGFloat
    let expandProgress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                powerOnBeam(in: geometry)
                    .shadow(color: color.opacity(beamGlowOpacity), radius: beamGlowRadius)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    private var beamGlowOpacity: Double {
        switch stage {
        case .dot, .pulse:
            return 0.75
        case .line:
            return 0.9
        case .expand:
            return 0.55 + Double(expandProgress) * 0.35
        case .complete:
            return 0
        }
    }

    private var beamGlowRadius: CGFloat {
        switch stage {
        case .dot, .pulse:
            return 6
        case .line:
            return 12
        case .expand:
            return 8 + expandProgress * 18
        case .complete:
            return 0
        }
    }

    @ViewBuilder
    private func powerOnBeam(in geometry: GeometryProxy) -> some View {
        let centerY = geometry.size.height / 2

        switch stage {
        case .dot, .pulse:
            Circle()
                .fill(color.opacity(0.92))
                .frame(width: 6, height: 6)
                .scaleEffect(dotPulseScale)
                .position(x: geometry.size.width / 2, y: centerY)

        case .line:
            Capsule()
                .fill(color.opacity(0.95))
                .frame(width: geometry.size.width - 16, height: 3)
                .position(x: geometry.size.width / 2, y: centerY)

        case .expand:
            let expandedHeight = max(3, geometry.size.height * expandProgress)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.05),
                            color.opacity(0.22),
                            color.opacity(0.12),
                            color.opacity(0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: geometry.size.width, height: expandedHeight)
                .position(x: geometry.size.width / 2, y: centerY)

        case .complete:
            EmptyView()
        }
    }
}
