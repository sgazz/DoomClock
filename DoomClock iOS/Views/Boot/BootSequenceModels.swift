import Foundation

enum BootPhase {
    case bootingPhase1
    case awaitingOperator
    case bootingPhase2
    case complete
}

enum ShutdownStage {
    case none
    case collapse
    case line
    case dot
    case black
}

enum PowerOnStage {
    case dot
    case pulse
    case line
    case expand
    case complete
}

enum DesktopPanel {
    case settings
    case help
    case newCountdown
}

enum PreLoginStep {
    case terminalLine(String)
    case asciiBlock(String)
}

enum BootArchivePanelPhase: Equatable {
    case wifiScanning(frame: Int)
    case wifiConnected
    case archiveAuthorizing
    case archiveUnlocked
}

enum LoginField: Hashable {
    case name
    case purpose
}

enum NewCountdownField: Hashable {
    case title
    case matter
}

struct BootIdleArtifact: Identifiable {
    let id = UUID()
    let text: String
}
