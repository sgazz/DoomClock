import SwiftUI

struct EditDoomsdayView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var selectedDate = Date().addingTimeInterval(60 * 60)
    @State private var selectedHour = Calendar.current.component(.hour, from: Date().addingTimeInterval(60 * 60))
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date().addingTimeInterval(60 * 60))
    @State private var showsDateWarning = false
    @State private var isTransitioning = false
    @State private var hasInitializedPicker = false
    @State private var minimumDate = Date()

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
                        selectedDate: $selectedDate,
                        selectedHour: $selectedHour,
                        selectedMinute: $selectedMinute,
                        mode: mode,
                        minimumDate: minimumDate
                    )

                    if showsDateWarning {
                        Text("Choose a future date and time.")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(mode.accentColor)
                            .multilineTextAlignment(.center)
                    }

                    TerminalButton(title: "START COUNTDOWN", color: mode.primaryColor, isProminent: true) {
                        guard !isTransitioning else { return }
                        isTransitioning = true
                        guard viewModel.updateTargetDate(combinedSelectedDate()) else {
                            showsDateWarning = true
                            isTransitioning = false
                            return
                        }

                        DispatchQueue.main.async {
                            dismiss()
                        }
                    }
                    .disabled(isTransitioning)
                    .opacity(isTransitioning ? 0.55 : 1)
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
            let components = Calendar.current.dateComponents([.hour, .minute], from: targetDate)
            selectedDate = targetDate
            selectedHour = components.hour ?? 0
            selectedMinute = components.minute ?? 0
            DispatchQueue.main.async {
                hasInitializedPicker = true
            }
        }
        .onChange(of: selectedDate) { _, _ in
            guard hasInitializedPicker else { return }
            viewModel.notePickerValueChanged()
        }
        .onChange(of: selectedHour) { _, _ in
            guard hasInitializedPicker else { return }
            viewModel.notePickerValueChanged()
        }
        .onChange(of: selectedMinute) { _, _ in
            guard hasInitializedPicker else { return }
            viewModel.notePickerValueChanged()
        }
    }

    private func combinedSelectedDate() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        return Calendar.current.date(from: components) ?? selectedDate
    }
}
