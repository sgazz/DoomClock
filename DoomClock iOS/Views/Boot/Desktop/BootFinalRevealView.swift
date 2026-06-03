import SwiftUI

struct BootFinalRevealView: View {
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text("DOOMCLOCK OS READY")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .shadow(color: color.opacity(0.35), radius: 2)

            VStack(spacing: 6) {
                Text("Time doesn't end things.")
                Text("It reveals them.")
                Text("The Archive is open")
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.72))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.38), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.05))
                )
        )
        .terminalFlicker()
    }
}
