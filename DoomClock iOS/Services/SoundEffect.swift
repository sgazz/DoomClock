import Foundation

enum SoundEffect: String, CaseIterable {
    case boot
    case buttonTap
    case toggle
    case windowOpen
    case windowClose
    case settingsSave
    case defconWarning
    case midnightEvent
    case crtShutdown

    /// Base filename in the app bundle (without extension).
    var resourceName: String {
        switch self {
        case .boot:
            "boot"
        case .buttonTap:
            "button_tap"
        case .toggle:
            "toggle"
        case .windowOpen:
            "window_open"
        case .windowClose:
            "window_close"
        case .settingsSave:
            "settings_save"
        case .defconWarning:
            "defcon_warning"
        case .midnightEvent:
            "midnight_event"
        case .crtShutdown:
            "crt_shutdown"
        }
    }

    var supportedExtensions: [String] {
        ["caf", "wav"]
    }

    /// Minimum seconds between repeated plays of the same effect.
    var minimumPlayInterval: TimeInterval {
        switch self {
        case .buttonTap:
            0.08
        case .toggle:
            0.12
        case .windowOpen, .windowClose:
            0.20
        case .settingsSave:
            0.30
        case .boot:
            0.50
        case .defconWarning:
            1.00
        case .midnightEvent:
            2.00
        case .crtShutdown:
            1.0
        }
    }

    /// Per-effect gain applied on top of the global sound volume (0...1).
    var gainMultiplier: Float {
        switch self {
        case .buttonTap:
            0.35
        case .toggle:
            0.45
        case .windowOpen:
            0.55
        case .windowClose:
            0.50
        case .settingsSave:
            0.60
        case .boot:
            0.75
        case .defconWarning:
            0.85
        case .midnightEvent:
            1.00
        case .crtShutdown:
            0.85
        }
    }
}
