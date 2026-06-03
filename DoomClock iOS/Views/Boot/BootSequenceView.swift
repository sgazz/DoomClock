import SwiftUI
#if os(iOS)
import UIKit
#endif

struct BootSequenceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedLoginField: LoginField?
    @FocusState private var focusedCountdownField: NewCountdownField?

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
    @State private var archivePanelPhase: BootArchivePanelPhase = .wifiScanning(frame: 0)
    @State private var newCountdownTitle = ""
    @State private var newCountdownMatter = ""

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
                                onClose: closeDesktopPanel,
                                onClearIdentity: clearIdentityFromSettings,
                                onToggleHaptic: playSelectionHaptic
                            )
                            .zIndex(1)
                        }

                        if activeDesktopPanel == .help {
                            BootHelpPanel(
                                color: terminalColor,
                                onClose: closeDesktopPanel
                            )
                            .zIndex(1)
                        }

                        if activeDesktopPanel == .newCountdown {
                            BootNewCountdownPanel(
                                color: terminalColor,
                                title: $newCountdownTitle,
                                matter: $newCountdownMatter,
                                focusedField: $focusedCountdownField,
                                onContinue: continueNewCountdown,
                                onClose: closeDesktopPanel
                            )
                            .zIndex(1)
                        }

                        if showDashboard {
                            BootDashboardView(
                                color: terminalColor,
                                isDesktopActionsEnabled: bootPhase == .complete && !isShuttingDown && !isExitingBoot,
                                onNewCountdown: openNewCountdown,
                                onHelp: openHelp,
                                onSettings: openSettings,
                                onLogout: beginShutdown
                            )
                            .id("boot-dashboard")
                            .opacity(activeDesktopPanel != nil ? 0.52 : 1)
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
        archivePanelPhase = .wifiScanning(frame: 0)
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

        try? await Task.sleep(nanoseconds: 140_000_000)
        if Task.isCancelled { return }

        powerOnStage = .pulse
        for _ in 0..<2 {
            withAnimation(.easeOut(duration: 0.1)) {
                powerOnDotPulseScale = 1.38
            }
            try? await Task.sleep(nanoseconds: 170_000_000)
            if Task.isCancelled { return }

            withAnimation(.easeIn(duration: 0.11)) {
                powerOnDotPulseScale = 1
            }
            try? await Task.sleep(nanoseconds: 170_000_000)
            if Task.isCancelled { return }
        }

        withAnimation(.easeOut(duration: 0.1)) {
            powerOnDotPulseScale = 1.32
        }
        try? await Task.sleep(nanoseconds: 120_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeIn(duration: 0.1)) {
            powerOnDotPulseScale = 1
        }
        try? await Task.sleep(nanoseconds: 80_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeOut(duration: 0.18)) {
            powerOnStage = .line
        }
        try? await Task.sleep(nanoseconds: 160_000_000)
        if Task.isCancelled { return }

        withAnimation(.easeOut(duration: 0.26)) {
            powerOnStage = .expand
            powerOnExpandProgress = 1
        }
        playSelectionHaptic()
        try? await Task.sleep(nanoseconds: 240_000_000)
        if Task.isCancelled { return }

        powerOnStage = .complete
        withAnimation(.easeOut(duration: 0.2)) {
            powerOnOverlayOpacity = 0
        }
        hasCompletedPowerOn = true
        try? await Task.sleep(nanoseconds: 160_000_000)
        if Task.isCancelled { return }

        startBootSequence()
    }

    @MainActor
    private func runPhase1() async {
        guard bootPhase == .bootingPhase1 else { return }
        isAnimating = true

        if reduceMotion {
            visiblePreLoginCount = preLoginSteps.count
            archivePanelPhase = .archiveUnlocked
            progress = phaseOneProgressCap
            isAnimating = false
            bootPhase = .awaitingOperator
            return
        }

        for index in preLoginSteps.indices {
            if Task.isCancelled { return }

            let baseDelay = UInt64.random(in: 90_000_000...120_000_000)
            let jitter = UInt64.random(in: 20_000_000...55_000_000)
            try? await Task.sleep(nanoseconds: baseDelay + jitter)
            if Task.isCancelled { return }

            await maybeHesitateProgress()

            visiblePreLoginCount = index + 1
            progress = Double(index + 1) / Double(preLoginSteps.count) * phaseOneProgressCap

            if isArchiveControlPanelStep(preLoginSteps[index]) {
                await runArchiveControlPanelSequence()
            }

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

        let progressSpan = 1 - phaseOneProgressCap

        for index in lines.indices {
            if Task.isCancelled { return }

            let baseDelay = UInt64.random(in: 80_000_000...100_000_000)
            let jitter = UInt64.random(in: 18_000_000...50_000_000)
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
            archivePanelPhase = .archiveUnlocked
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

        try? await Task.sleep(nanoseconds: 200_000_000)

        withAnimation(.easeOut(duration: 0.2)) {
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
    private func openHelp() {
        guard bootPhase == .complete, !isShuttingDown, !isExitingBoot else { return }
        playSelectionHaptic()
        activeDesktopPanel = .help
    }

    @MainActor
    private func openNewCountdown() {
        guard bootPhase == .complete, !isShuttingDown, !isExitingBoot else { return }
        playSelectionHaptic()
        activeDesktopPanel = .newCountdown
        if !reduceMotion {
            focusedCountdownField = .title
        }
    }

    @MainActor
    private func continueNewCountdown() {
        guard bootPhase == .complete, !isShuttingDown, !isExitingBoot else { return }
        focusedCountdownField = nil
        activeDesktopPanel = nil
        enterArchive()
    }

    @MainActor
    private func closeDesktopPanel() {
        playSelectionHaptic()
        focusedCountdownField = nil
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
        focusedCountdownField = nil

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
        guard Double.random(in: 0..<1) < 0.28 else { return }

        let pause = UInt64.random(in: 80_000_000...120_000_000)
        try? await Task.sleep(nanoseconds: pause)
    }

    private func isArchiveControlPanelStep(_ step: PreLoginStep) -> Bool {
        if case .asciiBlock(let content) = step {
            return content == BootASCIIArt.archiveControlPanelMarker
        }
        return false
    }

    @MainActor
    private func runArchiveControlPanelSequence() async {
        if reduceMotion {
            archivePanelPhase = .archiveUnlocked
            return
        }

        let scanDuration = UInt64.random(in: 800_000_000...1_200_000_000)
        let frameInterval: UInt64 = 120_000_000
        var elapsed: UInt64 = 0
        var frame = 0

        archivePanelPhase = .wifiScanning(frame: 0)

        while elapsed < scanDuration {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: frameInterval)
            if Task.isCancelled { return }
            elapsed += frameInterval
            frame = (frame + 1) % 4
            archivePanelPhase = .wifiScanning(frame: frame)
        }

        archivePanelPhase = .wifiConnected
        try? await Task.sleep(nanoseconds: 60_000_000)
        if Task.isCancelled { return }

        archivePanelPhase = .archiveAuthorizing
        try? await Task.sleep(nanoseconds: 250_000_000)
        if Task.isCancelled { return }

        archivePanelPhase = .archiveUnlocked
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
            if isArchiveControlPanelStep(step) {
                TerminalASCIIBlockView(
                    content: BootASCIIArt.archiveControlBox(phase: archivePanelPhase),
                    color: terminalColor,
                    pulseOnAppear: true
                )
                .padding(.vertical, 4)
            } else {
                TerminalASCIIBlockView(
                    content: content,
                    color: terminalColor,
                    pulseOnAppear: true
                )
                .padding(.vertical, 4)
            }
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
            .asciiBlock(BootASCIIArt.archiveControlPanelMarker),
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
    static let archiveControlPanelMarker = "__ARCHIVE_CTRL_PANEL__"

    private static let wifiSpinnerA = ["|", "/", "-", "\\"]
    private static let wifiSpinnerB = ["|", "\\", "-", "/"]

    static func archiveControlBox(phase: BootArchivePanelPhase) -> String {
        switch phase {
        case .wifiScanning(let frame):
            let index = frame % 4
            let spinnerA = wifiSpinnerA[index]
            let spinnerB = wifiSpinnerB[index]
            return """
            ┌───────────────────────┬───────────────────────┐
            │ /DEV/ARCHIVE_CTRL     │ /DEV/WIFI_SCAN         │
            │ STATUS: LOCKED        │ STATUS: SCANNING       │
            │ ACCESS: RESTRICTED    │ NETWORKS: --            │
            │        ███████        │                       │
            │       ██     ██       │      \(spinnerA)     \(spinnerB)          │
            │       ██     ██       │                       │
            │     ██████████████    │                       │
            │      ███  ██  ███     │                       │
            │     ██████████████    │ SIGNAL: SEARCHING      │
            └───────────────────────┴───────────────────────┘
            """

        case .wifiConnected:
            return archiveControlBoxConnected(leftStatus: "STATUS: LOCKED", leftAccess: "ACCESS: RESTRICTED")

        case .archiveAuthorizing:
            return archiveControlBoxConnected(leftStatus: "STATUS: AUTHORIZING...", leftAccess: "ACCESS: RESTRICTED")

        case .archiveUnlocked:
            return archiveControlBoxConnected(leftStatus: "STATUS: UNLOCKED", leftAccess: "ACCESS: OPEN")
        }
    }

    private static func archiveControlBoxConnected(leftStatus: String, leftAccess: String) -> String {
        """
        ┌───────────────────────┬───────────────────────┐
        │ /DEV/ARCHIVE_CTRL     │ /DEV/WIFI_SCAN         │
        │ \(leftStatus.padding(toLength: 21, withPad: " ", startingAt: 0)) │ STATUS: CONNECTED      │
        │ \(leftAccess.padding(toLength: 21, withPad: " ", startingAt: 0)) │ NETWORKS: UNRESOLVED_7342│
        │        ███████        │          ▄            │
        │      ██       ██      │       ▄  █  ▄         │
        │      ██               │     ▄ █  █  █ ▄       │
        │     ██████████████    │       █  █  █         │
        │      ███  ██  ███     │          █            │
        │     ██████████████    │ SIGNAL: VERIFIED       │
        └───────────────────────┴───────────────────────┘
        """
    }

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
        "...23% ██████",
        "...38% █████████",
        "...50% ███████/████████",
        "...74% █████████████████████",
        "...91% ███████████████████████████",
        "...99,8% ████████████████████████████",
    ]
}

// MARK: - Login

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
                isLastInForm: false,
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
                isLastInForm: true,
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


#Preview {
    BootSequenceView(onComplete: {})
}
