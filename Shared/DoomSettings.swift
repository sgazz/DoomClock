import Foundation

struct DoomSettings {
    var targetDate: Date?
    var countdownStartDate: Date?
    var mode: DoomMode
    var hasCompletedOnboarding: Bool
    var canEditDoomsday: Bool

    static var defaults: DoomSettings {
        DoomSettings(
            targetDate: nil,
            countdownStartDate: nil,
            mode: .suspicious,
            hasCompletedOnboarding: false,
            canEditDoomsday: true
        )
    }
}
