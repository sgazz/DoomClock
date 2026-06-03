import SwiftUI

enum DoomClockUI {
    static let background = Color(red: 0.067, green: 0.078, blue: 0.059)

    static func title(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 28, weight: .semibold, design: .monospaced))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .terminalFlicker()
    }

    static func primaryText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.8))
            .multilineTextAlignment(.center)
            .lineLimit(6)
            .minimumScaleFactor(0.72)
    }

    static func humorText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .semibold, design: .monospaced))
            .foregroundStyle(color.opacity(0.72))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
    }

    static func secondaryText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.68))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    static func primaryButton(title: String, color: Color, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            DoomSoundService.play(.buttonTap)
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.black)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
    }

    static func secondaryButton(title: String, color: Color, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            DoomSoundService.play(.buttonTap)
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                        .allowsHitTesting(false)
                )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isDisabled)
    }

}
