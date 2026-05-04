import SwiftUI

struct DoomModeView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel

    private var currentMode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("THREAT MODE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(currentMode.primaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    ForEach(DoomMode.allCases) { mode in
                        TerminalButton(
                            title: mode.title,
                            color: mode.primaryColor,
                            isSelected: mode == currentMode
                        ) {
                            viewModel.setMode(mode)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
            }

            ScanlineOverlay(color: currentMode.primaryColor)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}
