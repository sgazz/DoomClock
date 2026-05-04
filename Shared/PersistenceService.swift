import Foundation

#if ENABLE_COMPLICATIONS
import WidgetKit
#endif

struct PersistenceService {
    enum Key {
        static let targetDate = "doomclock.targetDate"
        static let countdownStartDate = "doomclock.countdownStartDate"
        static let doomMode = "doomclock.doomMode"
        static let hasSeenIntro = "doomclock.hasSeenIntro"
        static let hasCompletedOnboarding = "doomclock.hasCompletedOnboarding"
        static let canEditDoomsday = "doomclock.canEditDoomsday"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = SharedDefaults.defaults) {
        self.defaults = defaults
    }

    func loadSettings() -> DoomSettings {
        let fallback = DoomSettings.defaults
        let targetDate = defaults.object(forKey: Key.targetDate) as? Date
        let countdownStartDate = defaults.object(forKey: Key.countdownStartDate) as? Date
        let modeRawValue = defaults.string(forKey: Key.doomMode) ?? fallback.mode.rawValue
        let mode = DoomMode(rawValue: modeRawValue) ?? fallback.mode
        let hasCompletedOnboarding = defaults.object(forKey: Key.hasCompletedOnboarding) as? Bool
            ?? defaults.object(forKey: Key.hasSeenIntro) as? Bool
            ?? fallback.hasCompletedOnboarding
        let canEditDoomsday = defaults.object(forKey: Key.canEditDoomsday) as? Bool ?? fallback.canEditDoomsday

        return DoomSettings(
            targetDate: targetDate,
            countdownStartDate: countdownStartDate,
            mode: mode,
            hasCompletedOnboarding: hasCompletedOnboarding,
            canEditDoomsday: canEditDoomsday
        )
    }

    func saveSettings(_ settings: DoomSettings) {
        if let targetDate = settings.targetDate {
            defaults.set(targetDate, forKey: Key.targetDate)
        } else {
            defaults.removeObject(forKey: Key.targetDate)
        }

        if let countdownStartDate = settings.countdownStartDate {
            defaults.set(countdownStartDate, forKey: Key.countdownStartDate)
        } else {
            defaults.removeObject(forKey: Key.countdownStartDate)
        }

        defaults.set(settings.mode.rawValue, forKey: Key.doomMode)
        defaults.set(settings.hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding)
        defaults.set(settings.canEditDoomsday, forKey: Key.canEditDoomsday)

        #if ENABLE_COMPLICATIONS
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
