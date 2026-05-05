import SwiftUI

struct DoomModeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var isProcessing = false
    @State private var isThreatPulsing = false
    @State private var selectedResultMode: DoomMode?

    private var currentMode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: currentMode.primaryColor)

            if let selectedResultMode {
                resultContent(for: selectedResultMode)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            } else {
                selectionContent
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            updateThreatPulse()
        }
    }

    private var selectionContent: some View {
        VStack(spacing: 8) {
            DoomClockUI.title("THREAT MODE", color: currentMode.primaryColor)

            VStack(spacing: 8) {
                VStack(spacing: 7) {
                    ForEach(DoomMode.allCases) { mode in
                        Button {
                            select(mode)
                        } label: {
                            Text(mode.title)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(mode == currentMode ? Color.black : mode.primaryColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(mode == currentMode ? mode.primaryColor : mode.primaryColor.opacity(0.08))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(
                                            mode.primaryColor.opacity(borderOpacity(for: mode)),
                                            lineWidth: mode == currentMode && isThreatPulsing ? 1.5 : 1
                                        )
                                        .allowsHitTesting(false)
                                )
                                .terminalPulse(
                                    color: mode.primaryColor,
                                    isActive: mode == currentMode && isThreatPulsing
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(isProcessing)
                        .opacity(isProcessing ? 0.55 : 1)
                    }
                }
            }
        }
    }

    private func resultContent(for mode: DoomMode) -> some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            DoomClockUI.title(mode.title, color: mode.primaryColor)
            DoomClockUI.primaryText(resultBody(for: mode), color: mode.primaryColor)

            DoomClockUI.primaryButton(title: "DONE", color: mode.primaryColor, isDisabled: isProcessing) {
                guard !isProcessing else { return }
                isProcessing = true
                dismiss()
            }

            Spacer(minLength: 0)
        }
    }

    private func select(_ mode: DoomMode) {
        guard !isProcessing else { return }
        isProcessing = true
        viewModel.setMode(mode)
        selectedResultMode = mode
        updateThreatPulse()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isProcessing = false
        }
    }

    private func borderOpacity(for mode: DoomMode) -> Double {
        guard mode == currentMode else {
            return 0.5
        }

        return isThreatPulsing ? 1 : 0.95
    }

    private func updateThreatPulse() {
        guard !reduceMotion else {
            isThreatPulsing = false
            return
        }

        guard currentMode == .critical || currentMode == .armageddon else {
            isThreatPulsing = false
            return
        }

        isThreatPulsing = false
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            isThreatPulsing = true
        }
    }

    private func resultBody(for mode: DoomMode) -> String {
        switch mode {
        case .calm:
            "All is fine.\nProbably."
        case .suspicious:
            "Something feels off."
        case .critical:
            "This is not ideal."
        case .armageddon:
            "Well...\nhere we go."
        }
    }
}
