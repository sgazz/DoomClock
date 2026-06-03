import Foundation

#if os(iOS)
import UIKit
#endif

enum DoomHapticEvent {
    case selection
    case success
    case warning
    case failure
    case bootStep
    case bootComplete
    case authenticate
    case enterArchive
    case logout
    case panelOpen
    case panelClose
    case clearIdentity
}

struct DoomHapticsService {
    static func play(_ event: DoomHapticEvent, enabled: Bool) {
        guard enabled else { return }

        #if os(iOS)
        switch event {
        case .selection, .panelOpen, .panelClose, .bootStep:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()

        case .success, .authenticate, .bootComplete, .enterArchive:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)

        case .warning, .clearIdentity, .logout:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)

        case .failure:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
        #endif
    }
}
