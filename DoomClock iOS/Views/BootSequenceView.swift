import SwiftUI
#if os(iOS)
import UIKit
#endif

private enum BootPhase {
    case bootingPhase1
    case awaitingOperator
    case bootingPhase2
    case complete
}

private enum PreLoginStep {
    case terminalLine(String)
    case asciiBlock(String)
}

private enum OperatorIdentityStore {
    static let nameKey = "doomclock.operatorName"
    static let purposeKey = "doomclock.operatorPurpose"

    static var name: String? {
        UserDefaults.standard.string(forKey: nameKey)
    }

    static var purpose: String? {
        UserDefaults.standard.string(forKey: purposeKey)
    }

    static func save(name: String, purpose: String) {
        let defaults = UserDefaults.standard
        defaults.set(name, forKey: nameKey)
        defaults.set(purpose, forKey: purposeKey)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: nameKey)
        defaults.removeObject(forKey: purposeKey)
    }
}

struct BootSequenceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedLoginField: LoginField?

    let onComplete: () -> Void

    @State private var bootPhase: BootPhase = .bootingPhase1
    @State private var visiblePreLoginCount = 0
    @State private var visiblePostLoginCount = 0
    @State private var operatorName = ""
    @State private var operatorPurpose = ""
    @State private var resolvedOperatorName = "Operator"
    @State private var resolvedPurposeLogLine = "> Purpose logged."
    @State private var hasAuthenticated = false
    @State private var isAnimating = false
    @State private var progress: Double = 0
    @State private var showFinalReveal = false
    @State private var showDashboard = false
    @State private var showEnterButton = false
    @State private var glitchOpacity: Double = 1
    @State private var hasPlayedCompleteHaptic = false
    @State private var bootTask: Task<Void, Never>?

    private let terminalColor = DoomMode.suspicious.primaryColor
    private let phaseOneProgressCap = 0.65

    private var preLoginSteps: [PreLoginStep] {
        Self.preLoginStepSequence
    }

    private static let preLoginStepSequence: [PreLoginStep] = makePreLoginSteps()

    var body: some View {
        ZStack {
            DoomClockUI.background
                .ignoresSafeArea()
                .allowsHitTesting(false)

            ScanlineOverlay(color: terminalColor)

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(preLoginSteps.prefix(visiblePreLoginCount).enumerated()), id: \.offset) { index, step in
                                preLoginStepView(step)
                                    .id("pre-\(index)")
                            }

                            if showsLoginBox {
                                BootOperatorLoginView(
                                    operatorName: $operatorName,
                                    operatorPurpose: $operatorPurpose,
                                    isInteractive: bootPhase == .awaitingOperator,
                                    focusedField: $focusedLoginField,
                                    color: terminalColor,
                                    onAuthenticate: authenticate,
                                    onClearIdentity: clearIdentity
                                )
                                .id("operator-login")
                                .padding(.top, 10)
                            }

                            if bootPhase == .bootingPhase2 || bootPhase == .complete {
                                ForEach(Array(postLoginLines.enumerated()), id: \.offset) { index, line in
                                    if index < visiblePostLoginCount {
                                        TerminalLineView(text: line, color: terminalColor)
                                            .id("post-\(index)")
                                    }
                                }
                            }

                            if isAnimating {
                                HStack(spacing: 0) {
                                    BlinkingCursorView(color: terminalColor)
                                    Spacer(minLength: 0)
                                }
                                .padding(.top, 2)
                            }

                            if visiblePreLoginCount > 0 {
                                BootStatusPanel(phase: bootPhase, color: terminalColor)
                                    .padding(.top, 18)
                                    .id("status-panel")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .opacity(glitchOpacity)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        accelerateCurrentPhase()
                    }
                    .onChange(of: visiblePreLoginCount) { _, _ in
                        scrollDuringAnimation(proxy: proxy, anchorID: "pre-\(max(visiblePreLoginCount - 1, 0))")
                    }
                    .onChange(of: visiblePostLoginCount) { _, _ in
                        scrollDuringAnimation(proxy: proxy, anchorID: "post-\(max(visiblePostLoginCount - 1, 0))")
                    }
                    .onChange(of: bootPhase) { _, phase in
                        switch phase {
                        case .awaitingOperator:
                            scrollToLogin(proxy: proxy)
                            if !reduceMotion {
                                focusedLoginField = .name
                            }
                        case .complete:
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("status-panel", anchor: .bottom)
                            }
                        default:
                            break
                        }
                    }
                }

                bottomChrome
            }
        }
        .onAppear {
            loadOperatorIdentity()
            startBootSequence()
        }
        .onDisappear {
            bootTask?.cancel()
            bootTask = nil
        }
    }

    private var showsLoginBox: Bool {
        switch bootPhase {
        case .bootingPhase1:
            false
        case .awaitingOperator, .bootingPhase2, .complete:
            true
        }
    }

    private var postLoginLines: [String] {
        [
            "> Loading system modules...",
            ">> CORE.TIMER                                [ OK ]",
            ">> THREAT.ANALYZER                           [ OK ]",
            ">> HUMAN.BEHAVIOR.PARSER                     [ OK ]",
            ">> REGISTRY.INTERFACE                        [ OK ]",
            ">> INCIDENT.RETRIEVER                        [ OK ]",
            ">> LESSON.EXTRACTOR                          [ OK ]",
            ">> NARRATIVE.ENGINE                          [ OK ]",
            ">> EMPATHY.PROTOCOL                          [ OK ]",
            ">> HUMOR.SAFETY.LAYER                        [ OK ]",
            ">",
            "> Synchronizing with The Registry...          [ OK ]",
            "> Connection established.",
            "> Operator identity accepted.",
            "> Welcome, \(resolvedOperatorName).",
            resolvedPurposeLogLine,
            "> DoomClock OS ready.",
            "> Archive Cycle 7342 confirmed.",
            "> What will you end today?",
        ]
    }

    private var bottomChrome: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(terminalColor.opacity(0.14))
                .frame(height: 1)

            VStack(spacing: 14) {
                TerminalProgressBar(
                    progress: progress,
                    color: terminalColor,
                    label: "LOADING ARCHIVE INDEX... \(Int((progress * 100).rounded()))%"
                )

                ScrollView {
                    VStack(spacing: 14) {
                        if showFinalReveal {
                            BootFinalRevealView(color: terminalColor)
                        }

                        if showDashboard {
                            BootDashboardView(color: terminalColor)
                                .id("boot-dashboard")
                        }

                        if showEnterButton {
                            Button(action: enterArchive) {
                                Text("[ ENTER THE ARCHIVE ]")
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundStyle(terminalColor)
                                    .shadow(color: terminalColor.opacity(0.35), radius: 2)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(terminalButtonBackground)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .frame(maxHeight: showFinalReveal ? 420 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(DoomClockUI.background)
    }

    private var terminalButtonBackground: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .stroke(terminalColor.opacity(0.55), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(terminalColor.opacity(0.06))
            )
    }

    private func startBootSequence() {
        bootTask?.cancel()
        bootTask = Task {
            await runPhase1()
        }
    }

    @MainActor
    private func runPhase1() async {
        guard bootPhase == .bootingPhase1 else { return }
        isAnimating = true

        if reduceMotion {
            visiblePreLoginCount = preLoginSteps.count
            progress = phaseOneProgressCap
            isAnimating = false
            bootPhase = .awaitingOperator
            return
        }

        let baseDelay: UInt64 = 200_000_000

        for index in preLoginSteps.indices {
            if Task.isCancelled { return }

            let jitter = UInt64.random(in: 35_000_000...150_000_000)
            try? await Task.sleep(nanoseconds: baseDelay + jitter)
            if Task.isCancelled { return }

            visiblePreLoginCount = index + 1
            progress = Double(index + 1) / Double(preLoginSteps.count) * phaseOneProgressCap

            if index.isMultiple(of: 6) {
                await pulseGlitch()
            }
        }

        isAnimating = false
        bootPhase = .awaitingOperator
        playSelectionHaptic()
    }

    @MainActor
    private func runPhase2() async {
        guard bootPhase == .bootingPhase2 else { return }
        isAnimating = true

        let lines = postLoginLines

        if reduceMotion {
            visiblePostLoginCount = lines.count
            progress = 1
            isAnimating = false
            await finishBoot(staggerButton: false)
            return
        }

        let baseDelay: UInt64 = 180_000_000
        let progressSpan = 1 - phaseOneProgressCap

        for index in lines.indices {
            if Task.isCancelled { return }

            let jitter = UInt64.random(in: 30_000_000...140_000_000)
            try? await Task.sleep(nanoseconds: baseDelay + jitter)
            if Task.isCancelled { return }

            visiblePostLoginCount = index + 1
            progress = phaseOneProgressCap + (Double(index + 1) / Double(lines.count) * progressSpan)

            if index.isMultiple(of: 5) {
                await pulseGlitch()
            }
        }

        isAnimating = false
        await finishBoot(staggerButton: true)
    }

    @MainActor
    private func authenticate() {
        guard bootPhase == .awaitingOperator else { return }

        resolvedOperatorName = displayName(from: operatorName)
        resolvedPurposeLogLine = purposeLogLine(from: operatorPurpose)
        OperatorIdentityStore.save(name: operatorName, purpose: operatorPurpose)
        hasAuthenticated = true
        focusedLoginField = nil
        playSuccessHaptic()

        bootPhase = .bootingPhase2
        visiblePostLoginCount = 0
        progress = phaseOneProgressCap

        bootTask?.cancel()
        bootTask = Task {
            await runPhase2()
        }
    }

    @MainActor
    private func accelerateCurrentPhase() {
        switch bootPhase {
        case .bootingPhase1:
            guard isAnimating || visiblePreLoginCount < preLoginSteps.count else { return }
            bootTask?.cancel()
            visiblePreLoginCount = preLoginSteps.count
            progress = phaseOneProgressCap
            isAnimating = false
            bootPhase = .awaitingOperator
            playSelectionHaptic()
        case .bootingPhase2:
            guard isAnimating || visiblePostLoginCount < postLoginLines.count else { return }
            bootTask?.cancel()
            visiblePostLoginCount = postLoginLines.count
            progress = 1
            isAnimating = false
            Task {
                await finishBoot(staggerButton: false)
            }
        case .awaitingOperator, .complete:
            break
        }
    }

    @MainActor
    private func finishBoot(staggerButton: Bool) async {
        guard bootPhase != .complete else { return }

        visiblePostLoginCount = postLoginLines.count
        progress = 1
        bootPhase = .complete
        playCompleteHapticIfNeeded()

        if reduceMotion || !staggerButton {
            showFinalReveal = true
            showDashboard = true
            showEnterButton = true
            return
        }

        withAnimation(.easeOut(duration: 0.25)) {
            showFinalReveal = true
            showDashboard = true
        }

        try? await Task.sleep(nanoseconds: 320_000_000)

        withAnimation(.easeOut(duration: 0.25)) {
            showEnterButton = true
        }
    }

    private func displayName(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Operator" : trimmed
    }

    private func purposeLogLine(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "> Purpose logged."
        }
        return "> Purpose logged: \(trimmed)"
    }

    @MainActor
    private func loadOperatorIdentity() {
        operatorName = OperatorIdentityStore.name ?? ""
        operatorPurpose = OperatorIdentityStore.purpose ?? ""
    }

    @MainActor
    private func clearIdentity() {
        guard bootPhase == .awaitingOperator else { return }

        OperatorIdentityStore.clear()
        operatorName = ""
        operatorPurpose = ""
        focusedLoginField = nil
        playSelectionHaptic()
    }

    private func scrollDuringAnimation(proxy: ScrollViewProxy, anchorID: String) {
        guard isAnimating, !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(anchorID, anchor: .bottom)
        }
    }

    private func scrollToLogin(proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo("operator-login", anchor: .center)
        } else {
            withAnimation(.easeOut(duration: 0.28)) {
                proxy.scrollTo("operator-login", anchor: .center)
            }
        }
    }

    private func enterArchive() {
        playSelectionHaptic()
        onComplete()
    }

    private func playCompleteHapticIfNeeded() {
        guard !hasPlayedCompleteHaptic else { return }
        hasPlayedCompleteHaptic = true
        playSelectionHaptic()
    }

    private func playSelectionHaptic() {
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
        #endif
    }

    private func playSuccessHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }

    @MainActor
    private func pulseGlitch() async {
        guard !reduceMotion else { return }
        glitchOpacity = 0.84
        try? await Task.sleep(nanoseconds: 50_000_000)
        glitchOpacity = 1
    }

    @ViewBuilder
    private func preLoginStepView(_ step: PreLoginStep) -> some View {
        switch step {
        case .terminalLine(let text):
            TerminalLineView(text: text, color: terminalColor)
        case .asciiBlock(let content):
            TerminalASCIIBlockView(content: content, color: terminalColor)
                .padding(.vertical, 4)
        }
    }

    private static func makePreLoginSteps() -> [PreLoginStep] {
        var steps: [PreLoginStep] = [
            .terminalLine("> BOOT.SEQUENCE.INITIATED"),
            .terminalLine("> DoomClock OS ∆7342.11"),
            .terminalLine("> Registry Revision: UNRESOLVED"),
            .terminalLine("> Archive Cycle 7342"),
            .terminalLine("> Some endings reserved"),
            .terminalLine(">"),
            .terminalLine("> Checking memory of unfinished endings...       [ OK ]"),
            .terminalLine("> Verifying symbolic countdown engine...         [ OK ]"),
            .terminalLine("> Establishing secure context...                 [ OK ]"),
            .terminalLine("> Calibrating temporal parameters...             [ OK ]"),
            .terminalLine("> Verifying certainty module...                  [ FAIL ]"),
            .terminalLine("> Certainty unavailable."),
            .terminalLine("> Loading curiosity instead...                   [ OK ]"),
            .terminalLine("> Connecting to The Registry...                  [ OK ]"),
            .terminalLine("> Resolving archive endpoints...                 [ OK ]"),
            .terminalLine("> Mounting encrypted volumes...                  [ OK ]"),
            .terminalLine("> Loading archive index...                       [ OK ]"),
            .terminalLine(">"),
            .terminalLine("> /DEV/ARCHIVE_CTRL"),
            .terminalLine("> Status: LOCKED"),
            .terminalLine("> Encryption: SYMBOLIC-AES-2047"),
            .terminalLine("> Access: RESTRICTED"),
            .terminalLine("> Integrity: UNKNOWN"),
            .terminalLine("> Override required."),
            .asciiBlock(BootASCIIArt.archiveControlBox),
            .terminalLine(">"),
            .terminalLine("> Requesting override keys..."),
            .terminalLine("> Override accepted."),
            .terminalLine("> Decrypting archive..."),
        ]

        for line in BootASCIIArt.decryptProgressLines {
            steps.append(.terminalLine(line))
        }

        steps.append(.terminalLine("> Archive found."))
        steps.append(.asciiBlock(BootASCIIArt.archiveFoundBlock))

        return steps
    }
}

// MARK: - ASCII Art

private enum BootASCIIArt {
    static let archiveControlBox = """
    ┌──────────────────────────────┐
    │ /DEV/ARCHIVE_CTRL            │
    │ STATUS: LOCKED               │
    │ ACCESS: RESTRICTED           │
    │                              │
    │        ███████               │
    │       ██     ██              │
    │       ██     ██              │
    │     ████████████             │
    │     ███  ██  ███             │
    │     ████████████             │
    └──────────────────────────────┘
    """

    static let archiveFoundBlock = """
    ARCHIVE ID: DC-00000001
    CLASSIFICATION: PERSONAL / SYMBOLIC
    CONTAINS:
      7,342 incidents
      2,104 lessons
      infinite echoes

    WARNING:
    Contents may cause reflection,
    clarity, and uncomfortable honesty.
    """

    static let decryptProgressLines = [
        "...10% ███",
        "...20% ██████",
        "...30% █████████",
        "...50% ███████████████",
        "...70% █████████████████████",
        "...90% ███████████████████████████",
        "...100% ██████████████████████████████",
    ]
}

private struct TerminalASCIIBlockView: View {
    let content: String
    let color: Color

    var body: some View {
        Text(content)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.84))
            .shadow(color: color.opacity(0.22), radius: 1.5)
            .multilineTextAlignment(.leading)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(color.opacity(0.28), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.black.opacity(0.2))
                    )
            )
    }
}

// MARK: - Login

private enum LoginField: Hashable {
    case name
    case purpose
}

private struct BootOperatorLoginView: View {
    @Binding var operatorName: String
    @Binding var operatorPurpose: String
    let isInteractive: Bool
    var focusedField: FocusState<LoginField?>.Binding
    let color: Color
    let onAuthenticate: () -> Void
    let onClearIdentity: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DOOMCLOCK OS ∆7342.11")
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)

                Text("The Archive of Things That End\nand the Lessons They Leave Behind")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.68))
                    .lineSpacing(4)
            }

            Text("Operator login required.")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.82))
                .padding(.top, 4)

            terminalField(label: "Name:", text: $operatorName, field: .name)
            terminalField(label: "Purpose:", text: $operatorPurpose, field: .purpose)

            if isInteractive {
                Button(action: onAuthenticate) {
                    Text("[ AUTHENTICATE ]")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(color.opacity(0.5), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(color.opacity(0.05))
                                )
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                Button(action: onClearIdentity) {
                    Text("[ CLEAR IDENTITY ]")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(color.opacity(0.48))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.35), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.black.opacity(0.22))
                )
        )
    }

    @ViewBuilder
    private func terminalField(label: String, text: Binding<String>, field: LoginField) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.72))

            if isInteractive {
                TextField("", text: text)
                    .focused(focusedField, equals: field)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.92))
                    .tint(color)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(field == .name ? .next : .continue)
                    .onSubmit {
                        if field == .name {
                            focusedField.wrappedValue = .purpose
                        } else {
                            onAuthenticate()
                        }
                    }
            } else {
                Text(text.wrappedValue.isEmpty ? "—" : text.wrappedValue)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(color.opacity(isInteractive ? 0.35 : 0.18))
                .frame(height: 1)
        }
    }
}

private struct BootFinalRevealView: View {
    let color: Color

    var body: some View {
        VStack(spacing: 10) {
            Text("DOOMCLOCK OS READY")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .shadow(color: color.opacity(0.35), radius: 2)

            VStack(spacing: 6) {
                Text("Time doesn't destroy.")
                Text("Understanding does.")
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.72))
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.38), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.05))
                )
        )
        .terminalFlicker()
    }
}

// MARK: - OS Dashboard

private struct BootDashboardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BootDashboardView: View {
    let color: Color

    @State private var containerWidth: CGFloat = 0

    private var useSideBySide: Bool {
        containerWidth >= 600
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if useSideBySide {
                    HStack(alignment: .top, spacing: 10) {
                        dashboardPanels
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        dashboardPanels
                    }
                }
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: BootDashboardWidthKey.self, value: geometry.size.width)
                }
            )
            .onPreferenceChange(BootDashboardWidthKey.self) { width in
                containerWidth = width
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("DOOMCLOCK OS ∆7342.11")
                Text("Registry Revision: UNRESOLVED")
                Text("Archive Cycle 7342")
                Text("Some endings reserved.")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.46))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var dashboardPanels: some View {
        BootDashboardPanel(title: "FINAL STATE (LOOP)", color: color) {
            VStack(alignment: .leading, spacing: 4) {
                dashboardMenuItem("> NEW COUNTDOWN", highlighted: true)
                dashboardMenuItem("> ACTIVE COUNTDOWNS")
                dashboardMenuItem("> ARCHIVE BROWSER")
                dashboardMenuItem("> INCIDENT OF THE DAY")
                dashboardMenuItem("> SETTINGS")
                dashboardMenuItem("> LOGOUT")
            }
        }

        BootDashboardPanel(title: "STATUS", color: color) {
            VStack(alignment: .leading, spacing: 5) {
                statusRow(label: "Archive Cycle:", value: "7342")
                statusRow(label: "Active Countdowns:", value: "1")
                statusRow(label: "Archived Incidents:", value: "7,342")
                statusRow(label: "Lessons Learned:", value: "2,104")
                statusRow(label: "Threat Level:", value: "THE TEA IS STILL WARM")
                statusRow(label: "System Integrity:", value: "STABLE")
                statusRow(label: "Registry Connection:", value: "SECURE", trailing: "★★★★")
            }
        }

        BootDashboardPanel(title: "SYSTEM FEED", color: color) {
            VStack(alignment: .leading, spacing: 10) {
                feedEntry(
                    headline: "> Someone activated DoomClock",
                    detail: "  12 seconds ago."
                )
                feedEntry(
                    headline: "> A lesson was learned",
                    detail: "  somewhere."
                )
                feedEntry(
                    headline: "> The universe continues",
                    detail: "  without consulting us."
                )
                Text("> As expected.")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
            }
        }
    }

    private func dashboardMenuItem(_ text: String, highlighted: Bool = false) -> some View {
        Text(text)
            .font(.system(size: 11, weight: highlighted ? .bold : .medium, design: .monospaced))
            .foregroundStyle(color.opacity(highlighted ? 0.98 : 0.62))
            .shadow(color: highlighted ? color.opacity(0.28) : .clear, radius: 1.5)
            .padding(.horizontal, highlighted ? 6 : 0)
            .padding(.vertical, highlighted ? 3 : 0)
            .background(
                highlighted
                    ? RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(color.opacity(0.22), lineWidth: 1)
                        )
                    : nil
            )
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusRow(label: String, value: String, trailing: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .foregroundStyle(color.opacity(0.58))
            if let trailing {
                Text(value)
                    .foregroundStyle(color.opacity(0.78))
                Spacer(minLength: 4)
                Text(trailing)
                    .foregroundStyle(color.opacity(0.72))
            } else {
                Text(value)
                    .foregroundStyle(color.opacity(0.78))
            }
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feedEntry(headline: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(headline)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.82))
            Text(detail)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.52))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BootDashboardPanel<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color.opacity(0.88))
                .shadow(color: color.opacity(0.22), radius: 1)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(color.opacity(0.28), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.black.opacity(0.2))
                )
        )
    }
}

private struct BootStatusPanel: View {
    let phase: BootPhase
    let color: Color

    private var isOpen: Bool {
        phase == .bootingPhase2 || phase == .complete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            statusLine(label: "ARCHIVE STATUS", value: isOpen ? "OPEN" : "LOCKED")
            statusLine(
                label: "OPERATOR",
                value: phase == .awaitingOperator ? "UNKNOWN" : (hasAuthenticatedOperator ? "PRESENT" : "UNKNOWN")
            )
            statusLine(label: "LESSONS INDEX", value: isOpen ? "READY" : "LOADING")
            statusLine(label: "REGISTRY LINK", value: isOpen ? "UNVERIFIED" : "UNSTABLE")
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .foregroundStyle(color.opacity(0.52))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(color.opacity(0.22), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.black.opacity(0.18))
                )
        )
    }

    private var hasAuthenticatedOperator: Bool {
        phase == .bootingPhase2 || phase == .complete
    }

    private func statusLine(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text("\(label):")
            Text(value)
                .foregroundStyle(color.opacity(isOpen ? 0.68 : 0.46))
        }
    }
}

private struct TerminalLineView: View {
    let text: String
    let color: Color

    var body: some View {
        Group {
            if let status = StatusLine.parse(text) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(status.prefix)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(status.marker)
                        .foregroundStyle(status.marker == "[ FAIL ]" ? color.opacity(0.62) : color.opacity(0.88))
                        .layoutPriority(1)
                }
            } else {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .foregroundStyle(color.opacity(text == ">" ? 0.35 : 0.88))
        .shadow(color: color.opacity(0.28), radius: 1.5)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct StatusLine {
        let prefix: String
        let marker: String

        static func parse(_ text: String) -> StatusLine? {
            let markers = ["[ OK ]", "[ FAIL ]"]
            guard let marker = markers.first(where: { text.contains($0) }),
                  let range = text.range(of: marker) else { return nil }
            let prefix = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            return StatusLine(prefix: prefix.isEmpty ? text : prefix + " ", marker: marker)
        }
    }
}

private struct TerminalProgressBar: View {
    let progress: Double
    let color: Color
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .stroke(color.opacity(0.35), lineWidth: 1)

                    RoundedRectangle(cornerRadius: 1, style: .continuous)
                        .fill(color.opacity(0.85))
                        .frame(width: max(geometry.size.width * progress, progress > 0 ? 4 : 0))
                        .shadow(color: color.opacity(0.4), radius: 2)
                }
            }
            .frame(height: 10)
        }
    }
}

private struct BlinkingCursorView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = true

    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.opacity(isVisible ? 0.95 : 0.15))
            .frame(width: 9, height: 15)
            .shadow(color: color.opacity(0.35), radius: 2)
            .onAppear {
                guard !reduceMotion else {
                    isVisible = true
                    return
                }

                isVisible = true
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}

#Preview {
    BootSequenceView(onComplete: {})
}
