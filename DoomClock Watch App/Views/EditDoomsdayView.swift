import SwiftUI

struct EditDoomsdayView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var selectedDay = Date()
    @State private var selectedHour = Calendar.current.component(.hour, from: Date().addingTimeInterval(5 * 60))
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date().addingTimeInterval(5 * 60))
    @State private var showsDateWarning = false
    @State private var isProcessing = false

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 9) {
                    TerminalDateTimePicker(
                        selectedDay: $selectedDay,
                        selectedHour: $selectedHour,
                        selectedMinute: $selectedMinute,
                        mode: mode
                    )

                    if showsDateWarning {
                        Text("Choose a future date and time.")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(mode.accentColor)
                            .multilineTextAlignment(.center)
                    }

                    TerminalButton(title: "START COUNTDOWN", color: mode.primaryColor, isProminent: true) {
                        guard !isProcessing else { return }
                        isProcessing = true
                        let finalDate = selectedDoomsdayDate()
                        guard viewModel.updateTargetDate(finalDate) else {
                            showsDateWarning = true
                            isProcessing = false
                            return
                        }

                        dismiss()
                    }
                    .disabled(isProcessing)
                    .opacity(isProcessing ? 0.55 : 1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
            }

            ScanlineOverlay(color: mode.primaryColor)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let fallbackDate = Date().addingTimeInterval(60 * 60)
            let targetDate = max(viewModel.settings.targetDate ?? fallbackDate, fallbackDate)
            selectedDay = targetDate
            selectedHour = Calendar.current.component(.hour, from: targetDate)
            selectedMinute = Calendar.current.component(.minute, from: targetDate)
        }
    }

    private func selectedDoomsdayDate() -> Date {
        DateTimeHelper.combine(day: selectedDay, hour: selectedHour, minute: selectedMinute)
    }
}
