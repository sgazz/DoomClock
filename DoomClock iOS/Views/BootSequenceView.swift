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

private enum ShutdownStage {
    case none
    case collapse
    case line
    case dot
    case black
}

private enum PowerOnStage {
    case dot
    case pulse
    case line
    case expand
    case complete
}

private enum DesktopPanel {
    case settings
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

private enum BootPreferencesStore {
    static let alwaysShowBootSequenceKey = "doomclock.alwaysShowBootSequence"
    static let enableCRTEffectsKey = "doomclock.enableCRTEffects"
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
    @State private var failFlashTrigger = 0
    @State private var hasPlayedCompleteHaptic = false
    @State private var bootTask: Task<Void, Never>?
    @State private var idleArtifacts: [BootIdleArtifact] = []
    @State private var idleArtifactTask: Task<Void, Never>?
    @State private var enterButtonTitle = "[ ENTER THE ARCHIVE ]"
    @State private var isExitingBoot = false
    @State private var bootExitOpacity: Double = 1
    @State private var isShuttingDown = false
    @State private var shutdownStage: ShutdownStage = .none
    @State private var shutdownCollapseScale: CGFloat = 1
    @State private var shutdownDotOpacity: Double = 1
    @State private var activeDesktopPanel: DesktopPanel?
    @AppStorage(BootPreferencesStore.alwaysShowBootSequenceKey) private var alwaysShowBootSequence = true
    @AppStorage(BootPreferencesStore.enableCRTEffectsKey) private var enableCRTEffects = true
    @State private var hasCompletedPowerOn = false
    @State private var powerOnStage: PowerOnStage = .dot
    @State private var powerOnDotPulseScale: CGFloat = 1
    @State private var powerOnExpandProgress: CGFloat = 0
    @State private var powerOnOverlayOpacity: Double = 1
    @State private var powerOnTask: Task<Void, Never>?

    private let maxIdleArtifacts = 8

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

            Group {
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
                        guard hasCompletedPowerOn, !isShuttingDown else { return }
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

            BootFlashOverlay(color: terminalColor, trigger: failFlashTrigger)
            }
            .scaleEffect(y: shutdownCollapseScale, anchor: .center)
            .opacity(hasCompletedPowerOn && (shutdownStage == .none || shutdownStage == .collapse) ? 1 : 0)

            if hasCompletedPowerOn, enableCRTEffects {
                ScanlineOverlay(color: terminalColor)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }

            if hasCompletedPowerOn, enableCRTEffects {
                CRTScanBeam(color: terminalColor)
                    .opacity(bootExitOpacity)
                    .allowsHitTesting(false)
                    .zIndex(1)
            }

            if !hasCompletedPowerOn {
                CRTPowerOnOverlay(
                    stage: powerOnStage,
                    color: terminalColor,
                    dotPulseScale: powerOnDotPulseScale,
                    expandProgress: powerOnExpandProgress
                )
                .opacity(powerOnOverlayOpacity)
                .zIndex(2)
            }

            if isShuttingDown {
                CRTShutdownOverlay(
                    stage: shutdownStage,
                    color: terminalColor,
                    dotOpacity: shutdownDotOpacity
                )
                .zIndex(3)
            }
        }
        .onAppear {
            powerOnTask = Task {
                await runPowerOnSequence()
            }
        }
        .onDisappear {
            powerOnTask?.cancel()
            powerOnTask = nil
            bootTask?.cancel()
            bootTask = nil
            stopIdleArtifacts()
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
            "> What will you understand before it ends?",
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

                        if activeDesktopPanel == .settings {
                            BootSettingsPanel(
                                color: terminalColor,
                                operatorNameDisplay: settingsOperatorNameDisplay,
                                purposeDisplay: settingsPurposeDisplay,
                                reduceMotionActive: reduceMotion,
                                alwaysShowBootSequence: $alwaysShowBootSequence,
                                enableCRTEffects: $enableCRTEffects,
                                onClose: closeSettings,
                                onClearIdentity: clearIdentityFromSettings,
                                onToggleHaptic: playSelectionHaptic
                            )
                            .zIndex(1)
                        }

                        if showDashboard {
                            BootDashboardView(
                                color: terminalColor,
                                isSettingsEnabled: bootPhase == .complete && !isShuttingDown && !isExitingBoot,
                                isLogoutEnabled: bootPhase == .complete && !isShuttingDown && !isExitingBoot,
                                onSettings: openSettings,
                                onLogout: beginShutdown
                            )
                            .id("boot-dashboard")
                            .opacity(activeDesktopPanel == .settings ? 0.52 : 1)
                        }

                        if bootPhase == .complete, !idleArtifacts.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(idleArtifacts) { artifact in
                                    BootIdleArtifactView(text: artifact.text, color: terminalColor)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(bootExitOpacity)
                        }

                        if showEnterButton {
                            Button(action: enterArchive) {
                                Text(enterButtonTitle)
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
                            .modifier(BootEnterArchivePulseModifier(isActive: !isExitingBoot && !isShuttingDown, color: terminalColor))
                            .disabled(isExitingBoot || isShuttingDown)
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

    private var settingsOperatorNameDisplay: String {
        let trimmed = operatorName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return resolvedOperatorName
    }

    private var settingsPurposeDisplay: String {
        let trimmed = operatorPurpose.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Not specified" : trimmed
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
        guard hasCompletedPowerOn else { return }
        bootTask?.cancel()
        bootTask = Task {
            await runPhase1()
        }
    }

    @MainActor
    private func runPowerOnSequence() async {
        loadOperatorIdentity()

        if reduceMotion {
            hasCompletedPowerOn = true
            powerOnStage = .complete
            powerOnOverlayOpacity = 0
            startBootSequence()
            return
        }

        powerOnStage = .dot
        powerOnDotPulseScale = 1
        powerOnExpandProgress = 0
        powerOnOverlayOpacity = 1

        try? await Task.sleep(nanoseconds: 200_000_000)
        if Task.isCancelled { return }

        powerOnStage = .pulse
        for _ in 0..<2 {
            withAnimation(.easeOut(duration: 0.12)) {
                powerOnDotPulseScale = 1.38
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }

            withAnimation(.easeIn(duration: 0.13)) {
                powerOnDotPulseScale = 1
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            if Task.isCancelled { return }
        }

        withAnimation(.easeOut(duration: 0.12)) {
            powerOnDotPulseScale = 1.32
        }
        try? await Task.sleep(nanoseconds: 180_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeIn(duration: 0.12)) {
            powerOnDotPulseScale = 1
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeOut(duration: 0.22)) {
            powerOnStage = .line
        }
        try? await Task.sleep(nanoseconds: 220_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeOut(duration: 0.32)) {
            powerOnStage = .expand
            powerOnExpandProgress = 1
        }
        playSelectionHaptic()
        try? await Task.sleep(nanoseconds: 320_000_000)
        if Task.isCancelled { return }

        powerOnStage = .complete
        withAnimation(.easeOut(duration: 0.25)) {
            powerOnOverlayOpacity = 0
        }
        hasCompletedPowerOn = true
        try? await Task.sleep(nanoseconds: 250_000_000)
        if Task.isCancelled { return }

        startBootSequence()
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

            await maybeHesitateProgress()

            visiblePreLoginCount = index + 1
            progress = Double(index + 1) / Double(preLoginSteps.count) * phaseOneProgressCap

            if case .terminalLine(let text) = preLoginSteps[index], text.contains("[ FAIL ]") {
                triggerFailFlash()
            }

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

            await maybeHesitateProgress()

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
        guard hasCompletedPowerOn else { return }

        switch bootPhase {
        case .bootingPhase1:
            guard isAnimating || visiblePreLoginCount < preLoginSteps.count else { return }
            bootTask?.cancel()
            if shouldFlashOnSkipFail(from: visiblePreLoginCount) {
                triggerFailFlash()
            }
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
            startIdleArtifacts()
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
        startIdleArtifacts()
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
        performClearIdentity(useWarningHaptic: false)
    }

    @MainActor
    private func clearIdentityFromSettings() {
        guard bootPhase == .complete, activeDesktopPanel == .settings else { return }
        performClearIdentity(useWarningHaptic: true)
    }

    @MainActor
    private func performClearIdentity(useWarningHaptic: Bool) {
        OperatorIdentityStore.clear()
        operatorName = ""
        operatorPurpose = ""
        focusedLoginField = nil
        resolvedOperatorName = "Operator"
        resolvedPurposeLogLine = "> Purpose logged."

        if useWarningHaptic {
            playWarningHaptic()
        } else {
            playSelectionHaptic()
        }
    }

    @MainActor
    private func openSettings() {
        guard bootPhase == .complete, !isShuttingDown, !isExitingBoot else { return }
        playSelectionHaptic()
        activeDesktopPanel = .settings
    }

    @MainActor
    private func closeSettings() {
        playSelectionHaptic()
        activeDesktopPanel = nil
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
        guard !isExitingBoot, !isShuttingDown else { return }

        stopIdleArtifacts()
        playSelectionHaptic()
        isExitingBoot = true

        if reduceMotion {
            onComplete()
            return
        }

        withAnimation(.easeOut(duration: 0.4)) {
            bootExitOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            onComplete()
        }
    }

    @MainActor
    private func beginShutdown() {
        guard bootPhase == .complete, !isShuttingDown, !isExitingBoot else { return }

        stopIdleArtifacts()
        playSelectionHaptic()
        activeDesktopPanel = nil
        isShuttingDown = true
        focusedLoginField = nil

        if reduceMotion {
            shutdownCollapseScale = 0.015
            shutdownStage = .black
            shutdownDotOpacity = 0
            finishShutdownSequence()
            return
        }

        shutdownStage = .collapse
        withAnimation(.easeIn(duration: 0.28)) {
            shutdownCollapseScale = 0.012
        }

        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard isShuttingDown else { return }

            shutdownStage = .line

            try? await Task.sleep(nanoseconds: 240_000_000)
            guard isShuttingDown else { return }

            withAnimation(.easeIn(duration: 0.18)) {
                shutdownStage = .dot
            }

            try? await Task.sleep(nanoseconds: 420_000_000)
            guard isShuttingDown else { return }

            withAnimation(.easeOut(duration: 0.55)) {
                shutdownStage = .black
                shutdownDotOpacity = 0
            }

            try? await Task.sleep(nanoseconds: 600_000_000)
            guard isShuttingDown else { return }

            finishShutdownSequence()
        }
    }

    private func finishShutdownSequence() {
        #if DEBUG
        // Do not use exit(0) in production/App Store builds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            exit(0)
        }
        #endif
    }

    @MainActor
    private func startIdleArtifacts() {
        guard bootPhase == .complete else { return }
        idleArtifactTask?.cancel()
        idleArtifactTask = Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            while !Task.isCancelled {
                appendIdleArtifact()
                await maybeFlickerEnterLabel()
                let delay = UInt64.random(in: 2_000_000_000...5_000_000_000)
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    @MainActor
    private func stopIdleArtifacts() {
        idleArtifactTask?.cancel()
        idleArtifactTask = nil
    }

    @MainActor
    private func appendIdleArtifact() {
        guard bootPhase == .complete else { return }

        var nextLine = Self.idleArtifactPool.randomElement() ?? "> idle.ping registry              [ OK ]"
        let lastText = idleArtifacts.last?.text
        while nextLine == lastText, Self.idleArtifactPool.count > 1 {
            nextLine = Self.idleArtifactPool.randomElement() ?? nextLine
        }

        let artifact = BootIdleArtifact(text: nextLine)
        if reduceMotion {
            idleArtifacts.append(artifact)
            trimIdleArtifacts()
        } else {
            withAnimation(.easeIn(duration: 0.28)) {
                idleArtifacts.append(artifact)
                trimIdleArtifacts()
            }
        }
    }

    private func trimIdleArtifacts() {
        if idleArtifacts.count > maxIdleArtifacts {
            idleArtifacts.removeFirst(idleArtifacts.count - maxIdleArtifacts)
        }
    }

    @MainActor
    private func maybeFlickerEnterLabel() async {
        guard showEnterButton, bootPhase == .complete, !reduceMotion else { return }
        guard Double.random(in: 0...1) < 0.28 else { return }

        let alternatives = Self.enterButtonLabelVariants.filter { $0 != enterButtonTitle }
        guard let alternate = alternatives.randomElement() else { return }

        enterButtonTitle = alternate
        try? await Task.sleep(nanoseconds: 420_000_000)
        guard !Task.isCancelled, bootPhase == .complete else { return }
        enterButtonTitle = "[ ENTER THE ARCHIVE ]"
    }

    private static let idleArtifactPool: [String] = [
        "> idle.ping registry              [ OK ]",
        "> archive echo received",
        "> unresolved ending detected nearby",
        "> lesson residue fluctuating",
        "> signal drift: acceptable",
        "> memory fragment indexed",
        "> no catastrophe detected",
        "> curiosity module still active",
        "> time passed normally",
        "> operator hesitation observed",
        "> emotional checksum pending",
        "> silence recorded",
    ]

    private static let enterButtonLabelVariants: [String] = [
        "[ ENTER THE ARCHIVE ]",
        "[ ENTER_THE_ARCHIVE ]",
        "[ ENTER ARCHIVE ]",
    ]

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

    private func playWarningHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
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
    private func maybeHesitateProgress() async {
        guard !reduceMotion else { return }
        guard Bool.random() else { return }

        let pause = UInt64.random(in: 150_000_000...250_000_000)
        try? await Task.sleep(nanoseconds: pause)
    }

    @MainActor
    private func triggerFailFlash() {
        guard !reduceMotion else { return }
        failFlashTrigger += 1
    }

    private func shouldFlashOnSkipFail(from visibleCount: Int) -> Bool {
        guard let failIndex = preLoginSteps.firstIndex(where: { step in
            if case .terminalLine(let text) = step {
                return text.contains("[ FAIL ]")
            }
            return false
        }) else {
            return false
        }
        return visibleCount <= failIndex
    }

    @MainActor
    private func pulseGlitch() async {
        guard !reduceMotion else { return }
        glitchOpacity = Double.random(in: 0.72...0.85)
        let duration = UInt64.random(in: 40_000_000...70_000_000)
        try? await Task.sleep(nanoseconds: duration)
        glitchOpacity = 1
    }

    @ViewBuilder
    private func preLoginStepView(_ step: PreLoginStep) -> some View {
        switch step {
        case .terminalLine(let text):
            TerminalLineView(text: text, color: terminalColor)
        case .asciiBlock(let content):
            TerminalASCIIBlockView(
                content: content,
                color: terminalColor,
                pulseOnAppear: true,
                wifiScanActive: content.contains("WIFI_SCAN") && bootPhase == .bootingPhase1
            )
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
            .terminalLine("> Loading curiosity instead...                  [ OK ]"),
            .terminalLine("> Connecting to The Registry...                  [ OK ]"),
            .terminalLine("> Locating unfinished lessons...                 [ OK ]"),
            .terminalLine("> Mounting encrypted volumes...                  [ OK ]"),
            .terminalLine("> Loading archive index...                       [ OK ]"),
            .terminalLine(">"),
            .terminalLine("> /DEV/ARCHIVE_CTRL"),
            .terminalLine("> Status: LOCKED"),
            .terminalLine("> Encryption: SYMBOLIC-AES-2047"),
            .terminalLine("> Access: RESTRICTED"),
            .terminalLine("> Integrity: PENDING"),
            .terminalLine("> Override required."),
            .terminalLine("> Scanning nearby unstable networks..."),
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
        ┌───────────────────────┬───────────────────────┐
        │ /DEV/ARCHIVE_CTRL     │ /DEV/WIFI_SCAN         │
         │ STATUS: LOCKED        │ STATUS: SCANNING      │
        │ ACCESS: RESTRICTED    │ NETWORKS: --          │
        │                        │                      │
        │         ███████       │          ▄            │
        │        ██     ██      │       ▄  █  ▄          │
        │        ██     ██      │     ▄ █  █  █ ▄       │
         │     ████████████     │       █  █  █         │
        │      ███  ██  ███     │          █            │
        │      ████████████     │   SIGNAL: SEARCHING   │
         └───────────────────────┴───────────────────────┘
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
    var pulseOnAppear: Bool = false
    var wifiScanActive: Bool = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(content)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.84))
                .shadow(color: color.opacity(0.22), radius: 1.5)
                .multilineTextAlignment(.leading)
                .lineSpacing(2)
                .fixedSize(horizontal: true, vertical: true)
        }
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
        .bootPulse(active: pulseOnAppear, color: color)
        .modifier(BootWiFiScanPulseModifier(isActive: wifiScanActive, color: color))
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

            TerminalInputLine(
                label: "Name:",
                text: $operatorName,
                field: .name,
                focusedField: focusedField,
                isInteractive: isInteractive,
                color: color,
                onSubmit: onAuthenticate,
                onNext: { focusedField.wrappedValue = .purpose }
            )
            TerminalInputLine(
                label: "Purpose:",
                text: $operatorPurpose,
                field: .purpose,
                focusedField: focusedField,
                isInteractive: isInteractive,
                color: color,
                onSubmit: onAuthenticate,
                onNext: { focusedField.wrappedValue = .purpose }
            )

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
}

private struct TerminalInputLine: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let label: String
    @Binding var text: String
    let field: LoginField
    var focusedField: FocusState<LoginField?>.Binding
    let isInteractive: Bool
    let color: Color
    let onSubmit: () -> Void
    let onNext: () -> Void

    private var isFocused: Bool {
        focusedField.wrappedValue == field
    }

    private var showBlockCursor: Bool {
        isInteractive && isFocused
    }

    private var fieldFont: Font {
        .system(size: 13, weight: .medium, design: .monospaced)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .font(fieldFont)
                .foregroundStyle(color.opacity(0.72))

            ZStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if isInteractive {
                        Text(text)
                            .font(fieldFont)
                            .foregroundStyle(color.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if showBlockCursor {
                            TerminalBlockCursor(color: color)
                        }
                    } else {
                        Text(text.isEmpty ? "—" : text)
                            .font(fieldFont)
                            .foregroundStyle(color.opacity(0.55))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(false)

                if isInteractive {
                    TextField("", text: $text)
                        .focused(focusedField, equals: field)
                        .font(fieldFont)
                        .foregroundStyle(Color.clear)
                        .tint(.clear)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(field == .name ? .next : .continue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onSubmit {
                            if field == .name {
                                onNext()
                            } else {
                                onSubmit()
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isInteractive else { return }
                focusedField.wrappedValue = field
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

private struct TerminalBlockCursor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = true

    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.opacity(isVisible ? 0.95 : 0.2))
            .frame(width: 10, height: 15)
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
                Text("Time doesn't end things.")
                Text("It reveals them.")
                Text("The Archive is open")
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

private struct BootSettingsPanel: View {
    let color: Color
    let operatorNameDisplay: String
    let purposeDisplay: String
    let reduceMotionActive: Bool
    @Binding var alwaysShowBootSequence: Bool
    @Binding var enableCRTEffects: Bool
    let onClose: () -> Void
    let onClearIdentity: () -> Void
    let onToggleHaptic: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            settingsTitleBar
                .padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    settingsInfoRow(label: "OPERATOR NAME:", value: operatorNameDisplay)
                    settingsInfoRow(label: "PURPOSE:", value: purposeDisplay)

                    settingsToggleRow(
                        label: "ALWAYS SHOW BOOT SEQUENCE",
                        isOn: alwaysShowBootSequence
                    ) {
                        alwaysShowBootSequence.toggle()
                        onToggleHaptic()
                    }

                    settingsToggleRow(
                        label: "CRT EFFECTS",
                        isOn: enableCRTEffects
                    ) {
                        enableCRTEffects.toggle()
                        onToggleHaptic()
                    }

                    settingsInfoRow(
                        label: "REDUCE MOTION:",
                        value: reduceMotionActive ? "SYSTEM ACTIVE" : "SYSTEM CONTROLLED"
                    )
                    settingsInfoRow(label: "ARCHIVE ACCESS:", value: "LOCAL ONLY")
                    settingsInfoRow(label: "REGISTRY LINK:", value: "UNVERIFIED")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 180)

            HStack(spacing: 10) {
                settingsActionButton(title: "[ CLOSE ]", prominent: true, action: onClose)
                settingsActionButton(title: "[ CLEAR IDENTITY ]", prominent: false, action: onClearIdentity)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.black.opacity(0.34))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(color.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: color.opacity(0.32), radius: 10, y: 2)
        .shadow(color: color.opacity(0.14), radius: 3, y: 0)
    }

    private var settingsTitleBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("SETTINGS / OPERATOR PREFERENCES")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.94))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                Text("[ ACTIVE WINDOW ]")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Rectangle()
                .fill(color.opacity(0.22))
                .frame(height: 1)
        }
    }

    private func settingsInfoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(0.52))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsToggleRow(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("[ \(isOn ? "X" : " ") ]")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(color.opacity(isOn ? 0.92 : 0.48))
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func settingsActionButton(title: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: prominent ? .bold : .semibold, design: .monospaced))
                .foregroundStyle(color.opacity(prominent ? 0.92 : 0.62))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(color.opacity(prominent ? 0.5 : 0.32), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(color.opacity(prominent ? 0.06 : 0.03))
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct BootDashboardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct BootDashboardView: View {
    let color: Color
    var isSettingsEnabled: Bool = false
    var isLogoutEnabled: Bool = false
    let onSettings: () -> Void
    let onLogout: () -> Void

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
                dashboardMenuItem("> NEW COUNTDOWN", highlighted: false)
                dashboardMenuItem("> ACTIVE COUNTDOWNS")
                dashboardMenuItem("> ARCHIVE BROWSER")
                dashboardMenuItem("> INCIDENT OF THE DAY")
                dashboardSettingsItem
                dashboardLogoutItem
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
                    headline: "> The day continued",
                    detail: "  without asking permission."
                )
                Text("> As expected.")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(color.opacity(0.72))
            }
        }
    }

    private var dashboardSettingsItem: some View {
        Button(action: onSettings) {
            Text("> SETTINGS")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isSettingsEnabled ? 0.72 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isSettingsEnabled)
    }

    private var dashboardLogoutItem: some View {
        Button(action: onLogout) {
            Text("> LOGOUT")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(color.opacity(isLogoutEnabled ? 0.72 : 0.62))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!isLogoutEnabled)
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

private struct BootIdleArtifact: Identifiable {
    let id = UUID()
    let text: String
}

private struct BootIdleArtifactView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let text: String
    let color: Color

    @State private var opacity: Double = 0

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.58))
            .shadow(color: color.opacity(0.16), radius: 1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(opacity)
            .onAppear {
                if reduceMotion {
                    opacity = 1
                } else {
                    withAnimation(.easeIn(duration: 0.28)) {
                        opacity = 1
                    }
                }
            }
    }
}

private struct BootEnterArchivePulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let color: Color

    @State private var pulseAmount: Double = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.18 + pulseAmount * 0.22), radius: 2 + pulseAmount * 2.5)
            .opacity(0.9 + pulseAmount * 0.1)
            .onAppear {
                updatePulse()
            }
            .onChange(of: isActive) { _, _ in
                updatePulse()
            }
    }

    private func updatePulse() {
        guard isActive, !reduceMotion else {
            pulseAmount = 0
            return
        }

        pulseAmount = 0
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
            pulseAmount = 1
        }
    }
}

// MARK: - Boot Animations

/// CRT scan band: one full-screen sweep every `cycleDuration`, then idle until the next cycle.
private struct CRTScanBeam: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let color: Color

    private static let cycleDuration: TimeInterval = 10
    private static let sweepDuration: TimeInterval = 3.4
    private static var sweepPortion: Double { sweepDuration / cycleDuration }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion)) { timeline in
            GeometryReader { geometry in
                let cycleTime = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: Self.cycleDuration)
                let cyclePhase = cycleTime / Self.cycleDuration

                if cyclePhase < Self.sweepPortion, geometry.size.height > 0 {
                    let sweepProgress = cyclePhase / Self.sweepPortion
                    let envelope = sin(sweepProgress * .pi)
                    let beamHeight = max(geometry.size.height * 0.14, 40)
                    let travel = geometry.size.height + beamHeight
                    let y = sweepProgress * travel - beamHeight * 0.5

                    LinearGradient(
                        colors: [
                            color.opacity(0),
                            color.opacity(0.06 * envelope),
                            color.opacity(0.14 * envelope),
                            color.opacity(0.06 * envelope),
                            color.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geometry.size.width, height: beamHeight)
                    .offset(y: y)
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct BootFlashOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let color: Color
    let trigger: Int

    @State private var flashAmount: Double = 0

    var body: some View {
        ZStack {
            color.opacity(0.035 * flashAmount)
            Color.orange.opacity(0.028 * flashAmount)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in
            playFlash()
        }
    }

    private func playFlash() {
        guard !reduceMotion else { return }
        flashAmount = 1
        withAnimation(.easeOut(duration: 0.07)) {
            flashAmount = 0.55
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            withAnimation(.easeOut(duration: 0.2)) {
                flashAmount = 0
            }
        }
    }
}

private struct BootPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let active: Bool
    let color: Color

    @State private var glowAmount: Double = 0

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowAmount * 0.45), radius: glowAmount * 9)
            .onAppear {
                guard active, !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    glowAmount = 1
                }
                withAnimation(.easeIn(duration: 0.16).delay(0.22)) {
                    glowAmount = 0
                }
            }
    }
}

private struct BootWiFiScanPulseModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isActive: Bool
    let color: Color

    @State private var scanOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .opacity(scanOpacity)
            .shadow(color: isActive && !reduceMotion ? color.opacity((2 - scanOpacity) * 0.18) : .clear, radius: 2)
            .onAppear {
                updateScanAnimation()
            }
            .onChange(of: isActive) { _, _ in
                updateScanAnimation()
            }
    }

    private func updateScanAnimation() {
        guard isActive, !reduceMotion else {
            scanOpacity = 1
            return
        }

        scanOpacity = 1
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            scanOpacity = 0.78
        }
    }
}

private extension View {
    func bootPulse(active: Bool, color: Color) -> some View {
        modifier(BootPulseModifier(active: active, color: color))
    }
}

private struct CRTPowerOnOverlay: View {
    let stage: PowerOnStage
    let color: Color
    let dotPulseScale: CGFloat
    let expandProgress: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()

                powerOnBeam(in: geometry)
                    .shadow(color: color.opacity(beamGlowOpacity), radius: beamGlowRadius)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    private var beamGlowOpacity: Double {
        switch stage {
        case .dot, .pulse:
            return 0.75
        case .line:
            return 0.9
        case .expand:
            return 0.55 + Double(expandProgress) * 0.35
        case .complete:
            return 0
        }
    }

    private var beamGlowRadius: CGFloat {
        switch stage {
        case .dot, .pulse:
            return 6
        case .line:
            return 12
        case .expand:
            return 8 + expandProgress * 18
        case .complete:
            return 0
        }
    }

    @ViewBuilder
    private func powerOnBeam(in geometry: GeometryProxy) -> some View {
        let centerY = geometry.size.height / 2

        switch stage {
        case .dot, .pulse:
            Circle()
                .fill(color.opacity(0.92))
                .frame(width: 6, height: 6)
                .scaleEffect(dotPulseScale)
                .position(x: geometry.size.width / 2, y: centerY)

        case .line:
            Capsule()
                .fill(color.opacity(0.95))
                .frame(width: geometry.size.width - 16, height: 3)
                .position(x: geometry.size.width / 2, y: centerY)

        case .expand:
            let expandedHeight = max(3, geometry.size.height * expandProgress)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.05),
                            color.opacity(0.22),
                            color.opacity(0.12),
                            color.opacity(0.05),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: geometry.size.width, height: expandedHeight)
                .position(x: geometry.size.width / 2, y: centerY)

        case .complete:
            EmptyView()
        }
    }
}

private struct CRTShutdownOverlay: View {
    let stage: ShutdownStage
    let color: Color
    let dotOpacity: Double

    var body: some View {
        ZStack {
            Color.black
                .opacity(stage == .black ? 1 : 0)
                .animation(.easeOut(duration: 0.55), value: stage)

            if stage == .line || stage == .dot {
                shutdownBeam
                    .shadow(color: color.opacity(0.85), radius: stage == .line ? 10 : 4)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private var shutdownBeam: some View {
        if stage == .line {
            Capsule()
                .fill(color.opacity(0.95))
                .frame(height: 3)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
        } else {
            Circle()
                .fill(color.opacity(0.92))
                .frame(width: 6, height: 6)
                .opacity(dotOpacity)
        }
    }
}

#Preview {
    BootSequenceView(onComplete: {})
}
