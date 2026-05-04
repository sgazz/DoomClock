import Foundation

struct CountdownFormatter {
    static func complicationText(from targetDate: Date?) -> String {
        guard let targetDate else {
            return "--"
        }

        let remaining = targetDate.timeIntervalSinceNow
        guard remaining > 0 else {
            return "END"
        }

        let secondsPerDay: TimeInterval = 24 * 60 * 60
        let secondsPerHour: TimeInterval = 60 * 60

        if remaining >= secondsPerDay {
            return "D-\(Int(remaining / secondsPerDay))"
        }

        if remaining >= secondsPerHour {
            return "\(Int(remaining / secondsPerHour))h"
        }

        return "\(max(Int(ceil(remaining / 60)), 1))m"
    }

    static func rectangularSubtitle(from targetDate: Date?) -> String {
        guard let targetDate else {
            return "NO TARGET"
        }

        let remaining = targetDate.timeIntervalSinceNow
        guard remaining > 0 else {
            return "ZERO POINT"
        }

        return remaining < 24 * 60 * 60 ? "FINAL PHASE" : "FICTIONAL COUNTDOWN"
    }

    static func progress(from targetDate: Date?) -> Double {
        guard let targetDate else {
            return 0
        }

        let persistenceService = PersistenceService()
        let startDate = persistenceService.loadSettings().countdownStartDate
        guard let startDate, targetDate > startDate else {
            return 0
        }

        let total = targetDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        guard total > 0 else {
            return 0
        }

        return min(max(elapsed / total, 0), 1)
    }
}
