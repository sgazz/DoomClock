import WatchKit

struct HapticsService {
    func playModeChange() {
        play(.click)
    }

    func playPresetDateSet() {
        play(.success)
    }

    func playInvalidDateAttempt() {
        play(.failure)
    }

    func playOnboardingCompleted() {
        play(.success)
    }

    func playTargetConfirmed() {
        play(.success)
    }

    func playEditSaved() {
        play(.success)
    }

    func playResetNotification() {
        play(.notification)
    }

    private func play(_ type: WKHapticType) {
        WKInterfaceDevice.current().play(type)
    }
}
