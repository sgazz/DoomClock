import SwiftUI

private enum OnboardingStep {
    case intro
    case dateIntro
    case date
    case timeIntro
    case time
    case confirmIntro
    case confirm
    case editingIntro
    case editing
    case initializedIntro
}

struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var viewModel: CountdownViewModel
    @State private var step: OnboardingStep = .intro
    @State private var selectedDate: Date
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var canEdit = true
    @State private var isProcessing = false
    @State private var showsDateWarning = false
    @State private var isConfirmPulsing = false

    init() {
        let initial = Date().addingTimeInterval(5 * 60)
        _selectedDate = State(initialValue: Calendar.current.startOfDay(for: initial))
        _selectedHour = State(initialValue: Calendar.current.component(.hour, from: initial))
        _selectedMinute = State(initialValue: Calendar.current.component(.minute, from: initial))
    }

    private var mode: DoomMode {
        viewModel.settings.mode
    }

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: mode.primaryColor)

            if isMicroIntro {
                microIntroContent
                    .padding(.horizontal, step == .intro ? 0 : 12)
                    .padding(.vertical, step == .intro ? 0 : 8)
            } else {
                VStack(spacing: 8) {
                    glanceContent
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
    }

    private var glanceContent: some View {
        VStack(spacing: 8) {
            switch step {
            case .intro:
                DoomClockUI.title("SET THE DATE\nOF THE END…\nOF SOMETHING", color: mode.primaryColor)
                DoomClockUI.primaryText(
                    "Pick a day.\nSet the time.\n\nDon’t worry —\nnothing will\nactually happen.\n\nSomeone said\neverything is\nunder control.\n\nThat same someone\nhas never been right.",
                    color: mode.primaryColor
                )
                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    showsDateWarning = false
                    step = .dateIntro
                }

            case .dateIntro, .timeIntro, .confirmIntro, .editingIntro, .initializedIntro:
                EmptyView()

            case .date:
                compactDatePicker
                primaryButton(title: "NEXT: TIME") {
                    guard !isProcessing else { return }
                    showsDateWarning = false
                    step = .timeIntro
                }

            case .time:
                compactTimePicker
                primaryButton(title: "NEXT: CONFIRM") {
                    guard !isProcessing else { return }
                    showsDateWarning = false
                    step = .confirmIntro
                }

            case .confirm:
                DoomClockUI.title("TARGET LOCKED", color: mode.primaryColor)
                confirmContent
                warningText
                primaryButton(title: "CONFIRM") {
                    guard !isProcessing else { return }
                    guard let finalDate = selectedFinalDate(), viewModel.isFutureDate(finalDate) else {
                        showsDateWarning = true
                        viewModel.noteInvalidDateAttempt()
                        return
                    }

                    showsDateWarning = false
                    viewModel.noteTargetConfirmed()
                    step = .editingIntro
                }
                secondaryButton(title: "BACK") {
                    guard !isProcessing else { return }
                    showsDateWarning = false
                    step = .time
                }

            case .editing:
                DoomClockUI.title("ALLOW CHANGES?", color: mode.primaryColor)
                DoomClockUI.primaryText("You can edit this later.", color: mode.primaryColor)
                primaryButton(title: "YES, ALLOW") {
                    guard !isProcessing else { return }
                    canEdit = true
                    step = .initializedIntro
                }
                secondaryButton(title: "NO, LOCK IT") {
                    guard !isProcessing else { return }
                    canEdit = false
                    step = .initializedIntro
                }
            }
        }
    }

    private var compactTimePicker: some View {
        VStack(spacing: 6) {
            Text("SET TIME")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            Text("HOUR / MIN")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.58))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            HStack(spacing: 8) {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d", hour))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .clipped()

                Picker("Minute", selection: $selectedMinute) {
                    ForEach(0..<60, id: \.self) { minute in
                        Text(String(format: "%02d", minute))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .monospacedDigit()
                            .tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 76)
                .clipped()
            }
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.42), lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
    }

    private var compactDatePicker: some View {
        VStack(spacing: 6) {
            Text("CHOOSE DATE")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(1)

            Text("DAY / MONTH / YEAR")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.58))
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            DatePicker(
                "",
                selection: dateOnlyBinding,
                in: Calendar.current.startOfDay(for: Date())...,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.wheel)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .clipped()
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.18))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.42), lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
    }

    @ViewBuilder
    private var microIntroContent: some View {
        if step == .intro {
            firstIntroContent
        } else if step == .dateIntro {
            dateIntroContent
        } else if step == .timeIntro {
            timeIntroContent
        } else if step == .confirmIntro {
            confirmIntroContent
        } else if step == .editingIntro {
            editingIntroContent
        } else if step == .initializedIntro {
            initializedIntroContent
        } else {
            standardMicroIntroContent
        }
    }

    private var firstIntroContent: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("DOOMCLOCK // INITIAL BRIEFING")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(mode.primaryColor.opacity(0.42))
                            .tracking(1.1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 18)

                        Text("SET THE DATE\nOF THE END…\nOF SOMETHING")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundStyle(mode.primaryColor)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .terminalFlicker()
                            .padding(.bottom, 32)

                        VStack(alignment: .leading, spacing: 26) {
                            ForEach(introBriefingParagraphs, id: \.self) { paragraph in
                                introBriefingParagraph(paragraph)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: max(geometry.size.height - introBottomBarHeight, 0),
                        alignment: .topLeading
                    )
                }

                introBottomBar
            }
        }
    }

    private var introBottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(mode.primaryColor.opacity(0.14))
                .frame(height: 1)

            primaryButton(title: "CONTINUE") {
                guard !isProcessing else { return }
                continueFromMicroIntro()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 8)
        }
        .background(DoomClockUI.background)
    }

    private var introBottomBarHeight: CGFloat { 90 }

    private var introBriefingParagraphs: [String] {
        [
            "Pick a day.\nSet the time.",
            """
            The following entry will be logged as your chosen endpoint.
            No alarms will sound.
            No agency will be notified.
            """,
            "Don't worry — nothing will actually happen.",
            "Someone senior once said everything is under control.",
            "That same someone has never been right about anything important.",
            """
            You are reading an official DoomClock briefing.
            Treat it accordingly.
            """,
            "Proceed when ready.\nAuthorization is assumed.",
        ]
    }

    private func introBriefingParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundStyle(mode.primaryColor.opacity(0.76))
            .multilineTextAlignment(.leading)
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateIntroContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("NO PRESSURE")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.72)
                    .terminalFlicker()

                Text("The End doesn’t really use a calendar.")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                Text("↓")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .opacity(0.5)

                Text("""
                It just shows up,
                knocks politely,
                and offers tea.

                The date is mostly a formality.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    continueFromMicroIntro()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var timeIntroContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("SET THE MOMENT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.72)
                    .terminalFlicker()

                Text("""
                Choose the exact
                moment.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                Text("↓")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .opacity(0.5)

                Text("""
                The universe is
                about thirteen
                and a half billion
                years old

                and it has never
                asked for your
                opinion.

                This is your
                chance to
                respond.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    continueFromMicroIntro()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var confirmIntroContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("THIS IS IT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.72)
                    .terminalFlicker()

                VStack(spacing: 4) {
                    Text(formattedConfirmIntroDate)
                    Text("at \(formattedConfirmIntroTime)")
                }
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)
                .multilineTextAlignment(.center)
                .monospacedDigit()
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

                Text("↓")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .opacity(0.5)

                Text("""
                It looks official.
                Even slightly threatening.

                The universe has
                received the notice
                and decided to ignore it,

                which is, basically,
                its usual policy.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    continueFromMicroIntro()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var editingIntroContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("FREE WILL")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.72)
                    .terminalFlicker()

                Text("""
                You can still
                change your mind.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                Text("↓")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .opacity(0.5)

                Text("""
                Free will is
                an incredibly
                overrated concept,

                but you still
                have it.

                You can change
                the date,

                lock it forever,

                or just walk around
                feeling like you did
                something important.

                All three options
                have roughly
                the same effect
                on the universe.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    continueFromMicroIntro()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var initializedIntroContent: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("NOTHING CAN STOP IT")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .minimumScaleFactor(0.72)
                    .terminalFlicker()

                Text("""
                Nothing can
                stop it now.

                Except you.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                Text("↓")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)
                    .opacity(0.5)

                Text("""
                And a random
                phone reset.

                And bad Wi-Fi
                at the worst
                possible moment.

                The universe
                is full of irony,

                and it is almost
                always at your
                expense.
                """)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity)

                primaryButton(title: "CONTINUE") {
                    guard !isProcessing else { return }
                    continueFromMicroIntro()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var standardMicroIntroContent: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 0)

            DoomClockUI.title(microIntroTitle, color: mode.primaryColor)
            DoomClockUI.primaryText(microIntroBody, color: mode.primaryColor)

            primaryButton(title: "CONTINUE") {
                guard !isProcessing else { return }
                continueFromMicroIntro()
            }

            Spacer(minLength: 0)
        }
    }

    private var microIntroTitle: String {
        switch step {
        case .intro:
            "SET THE DATE\nOF THE END…\nOF SOMETHING"
        case .dateIntro:
            "NO PRESSURE"
        case .timeIntro:
            "SET THE MOMENT"
        case .confirmIntro:
            "THIS IS IT"
        case .editingIntro:
            "FREE WILL"
        case .initializedIntro:
            "NOTHING CAN STOP IT"
        default:
            ""
        }
    }

    private var microIntroBody: String {
        switch step {
        case .intro:
            "Pick a day.\nSet the time.\n\nDon’t worry —\nnothing will\nactually happen.\n\nSomeone said\neverything is\nunder control.\n\nThat same someone\nhas never been right."
        case .dateIntro:
            "The End doesn’t really use a calendar.\n\nIt just shows up,\nknocks politely,\nand offers tea.\n\nThe date is mostly a formality."
        case .timeIntro:
            "Choose the exact\nmoment.\n\nThe universe is\nabout thirteen\nand a half billion\nyears old\n\nand it has never\nasked for your\nopinion.\n\nThis is your\nchance to\nrespond."
        case .confirmIntro:
            "\(formattedConfirmIntroDate)\nat \(formattedConfirmIntroTime)\n\nIt looks official.\nEven slightly threatening.\n\nThe universe has\nreceived the notice\nand decided to ignore it,\n\nwhich is, basically,\nits usual policy."
        case .editingIntro:
            "You can still\nchange your mind.\n\nFree will is\nan incredibly\noverrated concept,\n\nbut you still\nhave it.\n\nYou can change\nthe date,\n\nlock it forever,\n\nor just walk around\nfeeling like you did\nsomething important.\n\nAll three options\nhave roughly\nthe same effect\non the universe."
        case .initializedIntro:
            "Nothing can\nstop it now.\n\nExcept you.\n\nAnd a random\nphone reset.\n\nAnd bad Wi-Fi\nat the worst\npossible moment.\n\nThe universe\nis full of irony,\n\nand it is almost\nalways at your\nexpense."
        default:
            ""
        }
    }

    private var isMicroIntro: Bool {
        switch step {
        case .intro, .dateIntro, .timeIntro, .confirmIntro, .editingIntro, .initializedIntro:
            true
        default:
            false
        }
    }

    private var confirmContent: some View {
        VStack(spacing: 8) {
            Text(formattedFinalDate)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)
                .lineLimit(1)
                .minimumScaleFactor(0.62)

            Text(String(format: "%02d:%02d", selectedHour, selectedMinute))
                .font(.system(size: 30, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(mode.primaryColor)
        }
        .terminalFlicker()
        .multilineTextAlignment(.center)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.2))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(mode.primaryColor.opacity(isConfirmPulsing ? 0.9 : 0.42), lineWidth: isConfirmPulsing ? 1.5 : 1)
                .allowsHitTesting(false)
        )
        .overlay {
            RetroBurstOverlay()
                .allowsHitTesting(false)
        }
        .shadow(color: isConfirmPulsing && !reduceMotion ? mode.primaryColor.opacity(0.25) : .clear, radius: 4)
        .onAppear {
            guard !reduceMotion else { return }
            isConfirmPulsing = false
            withAnimation(.easeOut(duration: 0.2)) {
                isConfirmPulsing = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isConfirmPulsing = false
                }
            }
        }
    }

    private func continueFromMicroIntro() {
        showsDateWarning = false

        switch step {
        case .intro:
            step = .dateIntro
        case .dateIntro:
            step = .date
        case .timeIntro:
            step = .time
        case .confirmIntro:
            step = .confirm
        case .editingIntro:
            step = .editing
        case .initializedIntro:
            completeOnboarding()
        default:
            break
        }
    }

    private func completeOnboarding() {
        guard let finalDate = selectedFinalDate(), viewModel.isFutureDate(finalDate) else {
            showsDateWarning = true
            viewModel.noteInvalidDateAttempt()
            step = .time
            return
        }

        isProcessing = true
        if !viewModel.completeOnboarding(targetDate: finalDate, canEdit: canEdit) {
            isProcessing = false
        }
    }

    private var warningText: some View {
        Group {
            if showsDateWarning {
                Text("Choose a future date and time.")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(mode.accentColor)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func dateTimePicker(for pickerStep: SelectionStep) -> some View {
        TerminalDateTimePicker(
            selectedDate: $selectedDate,
            selectedHour: $selectedHour,
            selectedMinute: $selectedMinute,
            step: pickerStep,
            mode: mode
        )
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        DoomClockUI.primaryButton(title: title, color: mode.primaryColor, isDisabled: isProcessing, action: action)
    }

    private func secondaryButton(title: String, action: @escaping () -> Void) -> some View {
        DoomClockUI.secondaryButton(title: title, color: mode.primaryColor, isDisabled: isProcessing, action: action)
    }

    private func selectedFinalDate() -> Date? {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = selectedHour
        components.minute = selectedMinute
        components.second = 0
        return Calendar.current.date(from: components)
    }

    private var dateOnlyBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { selectedDate = Calendar.current.startOfDay(for: $0) }
        )
    }

    private var formattedFinalDate: String {
        Self.dateFormatter.string(from: selectedDate).uppercased()
    }

    private var formattedConfirmIntroDate: String {
        Self.confirmIntroDateFormatter.string(from: selectedFinalDate() ?? selectedDate)
    }

    private var formattedConfirmIntroTime: String {
        String(format: "%02d:%02d", selectedHour, selectedMinute)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()

    private static let confirmIntroDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
}
