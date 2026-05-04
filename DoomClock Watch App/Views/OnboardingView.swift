import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var step = 0
    @State private var selectedDay: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var canEdit = true
    @State private var showsDateWarning = false
    @State private var isProcessing = false

    init() {
        let initialDate = Date().addingTimeInterval(5 * 60)
        _selectedDay = State(initialValue: initialDate)
        _selectedHour = State(initialValue: Calendar.current.component(.hour, from: initialDate))
        _selectedMinute = State(initialValue: Calendar.current.component(.minute, from: initialDate))
    }

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
                advance(to: 1)
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
    }

    private var dateStep: some View {
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
                let finalDate = selectedDoomsdayDate()
                guard viewModel.isFutureDate(finalDate) else {
                    showsDateWarning = true
                    viewModel.noteInvalidDateAttempt()
                    return
                }

                showsDateWarning = false
                advance(to: 2)
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
    }

    private var editingStep: some View {
        VStack(spacing: 18) {
            title("ALLOW FUTURE EDITING?")

            bodyText("Do you want to be able to edit your Doomsday date and time later?")

            TerminalButton(title: "YES, ALLOW EDITING", color: mode.primaryColor, isProminent: true) {
                canEdit = true
                advance(to: 3)
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)

            TerminalButton(title: "NO, LOCK IT", color: mode.primaryColor) {
                canEdit = false
                advance(to: 3)
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
    }

    private var startStep: some View {
        VStack(spacing: 18) {
            title("COUNTDOWN INITIALIZED")

            bodyText("Your fictional countdown is ready.")

            TerminalButton(title: "START", color: mode.primaryColor, isProminent: true) {
                guard !isProcessing else { return }
                isProcessing = true
                let finalDate = selectedDoomsdayDate()
                if !viewModel.completeOnboarding(targetDate: finalDate, canEdit: canEdit) {
                    isProcessing = false
                }
            }
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
    }

    private func selectedDoomsdayDate() -> Date {
        DateTimeHelper.combine(day: selectedDay, hour: selectedHour, minute: selectedMinute)
    }

    private func advance(to nextStep: Int) {
        guard !isProcessing else { return }
        isProcessing = true
        step = nextStep
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            isProcessing = false
        }
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
