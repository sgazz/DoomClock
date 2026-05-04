import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var step = 0
    @State private var selectedDate = Date().addingTimeInterval(60 * 60)
    @State private var selectedHour = Calendar.current.component(.hour, from: Date().addingTimeInterval(60 * 60))
    @State private var selectedMinute = Calendar.current.component(.minute, from: Date().addingTimeInterval(60 * 60))
    @State private var canEdit = true
    @State private var showsDateWarning = false
    @State private var isTransitioning = false
    @State private var minimumDate = Date()

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.08, blue: 0.06)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: step == 1 ? 9 : 22) {
                    switch step {
                    case 0:
                        explanationStep
                    case 1:
                        dateStep
                    case 2:
                        editingStep
                    default:
                        startStep
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, step == 1 ? 6 : 8)
            }

            ScanlineOverlay(color: mode.primaryColor)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var explanationStep: some View {
        VStack(spacing: 18) {
            title("PERSONAL DOOMSDAY TIMER")

            bodyText("""
            Set your personal fictional countdown.

            Not a prediction.
            Not a warning.

            Just a symbolic timer.
            """)

            TerminalButton(title: "CONTINUE", color: mode.primaryColor, isProminent: true) {
                guard !isTransitioning else { return }
                isTransitioning = true
                DispatchQueue.main.async {
                    step = 1
                    isTransitioning = false
                }
            }
            .disabled(isTransitioning)
            .opacity(isTransitioning ? 0.55 : 1)
        }
    }

    private var dateStep: some View {
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
                let targetDate = combinedSelectedDate()
                guard viewModel.isFutureDate(targetDate) else {
                    showsDateWarning = true
                    viewModel.noteInvalidDateAttempt()
                    return
                }

                showsDateWarning = false
                isTransitioning = true
                DispatchQueue.main.async {
                    step = 2
                    isTransitioning = false
                }
            }
            .disabled(isTransitioning)
            .opacity(isTransitioning ? 0.55 : 1)
        }
        .onChange(of: selectedDate) { _, _ in
            viewModel.notePickerValueChanged()
        }
        .onChange(of: selectedHour) { _, _ in
            viewModel.notePickerValueChanged()
        }
        .onChange(of: selectedMinute) { _, _ in
            viewModel.notePickerValueChanged()
        }
    }

    private var editingStep: some View {
        VStack(spacing: 18) {
            title("ALLOW FUTURE EDITING?")

            bodyText("Do you want to be able to edit your Doomsday date and time later?")

            TerminalButton(title: "YES, ALLOW EDITING", color: mode.primaryColor, isProminent: true) {
                guard !isTransitioning else { return }
                isTransitioning = true
                DispatchQueue.main.async {
                    canEdit = true
                    step = 3
                    isTransitioning = false
                }
            }
            .disabled(isTransitioning)
            .opacity(isTransitioning ? 0.55 : 1)

            TerminalButton(title: "NO, LOCK IT", color: mode.primaryColor) {
                guard !isTransitioning else { return }
                isTransitioning = true
                DispatchQueue.main.async {
                    canEdit = false
                    step = 3
                    isTransitioning = false
                }
            }
            .disabled(isTransitioning)
            .opacity(isTransitioning ? 0.55 : 1)
        }
    }

    private var startStep: some View {
        VStack(spacing: 18) {
            title("COUNTDOWN INITIALIZED")

            bodyText("Your fictional countdown is ready.")

            TerminalButton(title: "START", color: mode.primaryColor, isProminent: true) {
                guard !isTransitioning else { return }
                isTransitioning = true
                let targetDate = combinedSelectedDate()
                DispatchQueue.main.async {
                    if !viewModel.completeOnboarding(targetDate: targetDate, canEdit: canEdit) {
                        isTransitioning = false
                    }
                }
            }
            .disabled(isTransitioning)
            .opacity(isTransitioning ? 0.55 : 1)
        }
    }

    private func combinedSelectedDate() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        return Calendar.current.date(from: components) ?? selectedDate
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(mode.primaryColor)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.72)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(mode.primaryColor.opacity(0.76))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}
