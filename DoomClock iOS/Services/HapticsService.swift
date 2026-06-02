#if os(iOS)
import UIKit

struct HapticsService {
    func playModeChange() {
        play(.light)
    }

    func playPresetDateSet() {
        play(.success)
    }

    func playInvalidDateAttempt() {
        play(.error)
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
        play(.warning)
    }

    private func play(_ style: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(style)
    }

    private func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}
#endif
