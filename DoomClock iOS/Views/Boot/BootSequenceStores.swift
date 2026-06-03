import Foundation

enum OperatorIdentityStore {
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

enum BootPreferencesStore {
    static let alwaysShowBootSequenceKey = "doomclock.alwaysShowBootSequence"
    static let enableCRTEffectsKey = "doomclock.enableCRTEffects"
    static let enableSoundsKey = "doomclock.enableSounds"
    static let soundVolumeKey = "doomclock.soundVolume"
    static let enableHapticsKey = "doomclock.enableHaptics"
    static let enableBootAnimationsKey = "doomclock.enableBootAnimations"
    static let showIncidentFeedKey = "doomclock.showIncidentFeed"
    static let showDailyIncidentKey = "doomclock.showDailyIncident"

    static var isSoundEnabled: Bool {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: enableSoundsKey) != nil else { return true }
        return defaults.bool(forKey: enableSoundsKey)
    }

    static var soundVolume: Float {
        let stored = UserDefaults.standard.object(forKey: soundVolumeKey) as? Double ?? 1
        return Float(min(max(stored, 0), 1))
    }
}
