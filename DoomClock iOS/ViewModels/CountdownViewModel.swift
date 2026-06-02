import Combine
import Foundation

@MainActor
final class CountdownViewModel: ObservableObject {
    struct RemainingTime {
        let days: Int
        let hours: Int
        let minutes: Int
        let seconds: Int

        static let zero = RemainingTime(days: 0, hours: 0, minutes: 0, seconds: 0)
    }

    @Published private(set) var settings: DoomSettings
    @Published private(set) var now: Date

    private let persistenceService: PersistenceService
    private let hapticsService: HapticsService
    private var timer: Timer?

    init(
        persistenceService: PersistenceService? = nil,
        hapticsService: HapticsService? = nil
    ) {
        let persistenceService = persistenceService ?? PersistenceService()
        self.persistenceService = persistenceService
        self.hapticsService = hapticsService ?? HapticsService()
        self.settings = persistenceService.loadSettings()
        self.now = Date()
    }

    var remainingTime: RemainingTime {
        guard let targetDate = settings.targetDate, !isExpired else {
            return .zero
        }

        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute, .second],
            from: now,
            to: targetDate
        )

        return RemainingTime(
            days: max(components.day ?? 0, 0),
            hours: max(components.hour ?? 0, 0),
            minutes: max(components.minute ?? 0, 0),
            seconds: max(components.second ?? 0, 0)
        )
    }

    var formattedRemainingTime: String {
        let remaining = remainingComponents
        return String(
            format: "%02d:%02d:%02d:%02d",
            remaining.days,
            remaining.hours,
            remaining.minutes,
            remaining.seconds
        )
    }

    var remainingComponents: RemainingTime {
        remainingTime
    }

    var hasTargetDate: Bool {
        settings.targetDate != nil
    }

    var hasCompletedOnboarding: Bool {
        settings.hasCompletedOnboarding
    }

    var canEditDoomsday: Bool {
        settings.canEditDoomsday
    }

    var isExpired: Bool {
        guard let targetDate = settings.targetDate else {
            return false
        }

        return targetDate <= now
    }

    func startTimer() {
        stopTimer()
        now = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.now = Date()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    @discardableResult
    func completeOnboarding(targetDate: Date, canEdit: Bool) -> Bool {
        guard isFutureDate(targetDate) else {
            hapticsService.playInvalidDateAttempt()
            return false
        }

        settings.targetDate = targetDate
        settings.countdownStartDate = Date()
        settings.canEditDoomsday = canEdit
        settings.hasCompletedOnboarding = true
        now = Date()
        persist()
        hapticsService.playOnboardingCompleted()
        return true
    }

    @discardableResult
    func updateTargetDate(_ date: Date) -> Bool {
        guard isFutureDate(date) else {
            hapticsService.playInvalidDateAttempt()
            return false
        }

        settings.targetDate = date
        settings.countdownStartDate = Date()
        now = Date()
        persist()
        hapticsService.playEditSaved()
        return true
    }

    func setMode(_ mode: DoomMode) {
        settings.mode = mode
        persist()
        hapticsService.playModeChange()
    }

    func resetOnboarding() {
        settings = DoomSettings.defaults
        now = Date()
        persist()
        hapticsService.playResetNotification()
    }

    func resetCountdown() {
        settings.targetDate = nil
        settings.countdownStartDate = nil
        settings.hasCompletedOnboarding = true
        now = Date()
        persist()
        hapticsService.playResetNotification()
    }

    func noteInvalidDateAttempt() {
        hapticsService.playInvalidDateAttempt()
    }

    func noteTargetConfirmed() {
        hapticsService.playTargetConfirmed()
    }

    func isFutureDate(_ date: Date) -> Bool {
        date > Date()
    }

    private func persist() {
        persistenceService.saveSettings(settings)
    }
}
