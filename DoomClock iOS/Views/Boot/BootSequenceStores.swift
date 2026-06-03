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
}
