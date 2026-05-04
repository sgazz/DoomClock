import SwiftUI

enum DoomMode: String, CaseIterable, Identifiable {
    case calm
    case suspicious
    case critical
    case armageddon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:
            "CALM"
        case .suspicious:
            "SUSPICIOUS"
        case .critical:
            "CRITICAL"
        case .armageddon:
            "ARMAGEDDON"
        }
    }

    var statusText: String {
        switch self {
        case .calm:
            "SYSTEM STABLE"
        case .suspicious:
            "ANOMALY WATCH"
        case .critical:
            "BUNKER ALERT"
        case .armageddon:
            "FINAL PROTOCOL"
        }
    }

    var primaryColor: Color {
        switch self {
        case .calm:
            Color(red: 0.47, green: 0.86, blue: 0.55)
        case .suspicious:
            Color(red: 0.78, green: 0.86, blue: 0.28)
        case .critical:
            Color(red: 1.0, green: 0.55, blue: 0.22)
        case .armageddon:
            Color(red: 0.95, green: 0.18, blue: 0.16)
        }
    }

    var accentColor: Color {
        switch self {
        case .calm:
            Color(red: 0.62, green: 0.98, blue: 0.68)
        case .suspicious:
            Color(red: 0.96, green: 0.94, blue: 0.36)
        case .critical:
            Color(red: 1.0, green: 0.72, blue: 0.38)
        case .armageddon:
            Color(red: 1.0, green: 0.42, blue: 0.36)
        }
    }
}
