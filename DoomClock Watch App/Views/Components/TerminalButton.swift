import SwiftUI

struct TerminalButton: View {
    let title: String
    var color: Color
    var isSelected = false
    var isProminent = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.caption2, design: .monospaced).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isProminent ? 8 : 6)
                .foregroundStyle(isSelected || isProminent ? Color.black : color)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill((isSelected || isProminent) ? color : color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(color.opacity(isSelected ? 0.95 : 0.55), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
