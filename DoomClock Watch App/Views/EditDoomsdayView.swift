import SwiftUI

struct EditDoomsdayView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var step: SelectionStep = .date
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var selectedHour = Calendar.current.component(.hour, from: Date().addingTimeInterval(5 * 60))
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date().addingTimeInterval(5 * 60))
    @State private var isProcessing = false
    @State private var showsDateWarning = false

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: mode.primaryColor)

            VStack(spacing: 8) {
                header

                TerminalDateTimePicker(
                    selectedDate: $selectedDate,
                    selectedHour: $selectedHour,
                    selectedMinute: $selectedMinute,
                    step: step,
                    mode: mode
                )

                if showsDateWarning {
                    Text("Choose a future date and time.")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(mode.accentColor)
                        .multilineTextAlignment(.center)
                }

                switch step {
                case .date:
                    primaryButton(title: "NEXT: TIME") {
                        guard !isProcessing else { return }
                        showsDateWarning = false
                        step = .time
                    }

                case .time:
                    primaryButton(title: "SAVE") {
                        guard !isProcessing else { return }
                        guard let finalDate = selectedFinalDate(), viewModel.isFutureDate(finalDate) else {
                            showsDateWarning = true
                            viewModel.noteInvalidDateAttempt()
                            return
                        }

                        isProcessing = true
                        showsDateWarning = false
                        guard viewModel.updateTargetDate(finalDate) else {
                            isProcessing = false
                            showsDateWarning = true
                            return
                        }

                        dismiss()
                    }

                    DoomClockUI.secondaryButton(title: "BACK: DATE", color: mode.primaryColor, isDisabled: isProcessing) {
                        guard !isProcessing else { return }
                        showsDateWarning = false
                        step = .date
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .onAppear {
            let initialDate = max(
                viewModel.settings.targetDate ?? Date().addingTimeInterval(5 * 60),
                Date().addingTimeInterval(5 * 60)
            )
            selectedDate = Calendar.current.startOfDay(for: initialDate)
            selectedHour = Calendar.current.component(.hour, from: initialDate)
            selectedMinute = Calendar.current.component(.minute, from: initialDate)
        }
    }

    private var header: some View {
        VStack(spacing: 3) {
            DoomClockUI.title(step == .date ? "EDIT DOOMSDAY" : "SET THE TIME", color: mode.primaryColor)
            DoomClockUI.primaryText(step == .date ? "Pick a date." : "Choose the moment.", color: mode.primaryColor)
        }
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        DoomClockUI.primaryButton(title: title, color: mode.primaryColor, isDisabled: isProcessing, action: action)
    }

    private func selectedFinalDate() -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        return Calendar.current.date(from: components)
    }
}
