import Foundation

#if os(iOS)
import AVFoundation
import AudioToolbox
#endif

/// Centralized UI sound playback for DoomClock iOS (boot + main app).
@MainActor
final class DoomSoundService {
    static let shared = DoomSoundService()

    private init() {}

    #if os(iOS)
    private var activePlayer: AVAudioPlayer?
    private var overlappingPlayers: [AVAudioPlayer] = []
    private var didConfigureSession = false
    private var lastPlayDates: [SoundEffect: Date] = [:]
    private var crtShutdownTask: Task<Void, Never>?
    #endif

    /// Plays a sound when sounds are enabled and volume > 0.
    static func play(_ effect: SoundEffect) {
        if effect == .crtShutdown {
            playCrtShutdown()
            return
        }
        shared.play(effect, ignoresEnabled: false, bypassThrottle: false)
    }

    /// CRT tube power-off: bundled `crt_shutdown` asset or procedural fallback synced to shutdown stages.
    static func playCrtShutdown() {
        shared.playCrtShutdownSequence(ignoresEnabled: false, bypassThrottle: false)
    }

    /// Settings preview for CRT shutdown; respects volume, ignores Sounds Enabled and throttle.
    static func playCrtShutdownTest() {
        shared.playCrtShutdownSequence(ignoresEnabled: true, bypassThrottle: true)
    }

    /// Preview from Settings; respects volume and gain, ignores the enabled toggle.
    static func playTest() {
        shared.play(.buttonTap, ignoresEnabled: true, bypassThrottle: true)
    }

    #if os(iOS)
    private func play(_ effect: SoundEffect, ignoresEnabled: Bool, bypassThrottle: Bool) {
        guard ignoresEnabled || BootPreferencesStore.isSoundEnabled else { return }

        let effectiveVolume = Self.effectiveVolume(
            globalVolume: BootPreferencesStore.soundVolume,
            gain: effect.gainMultiplier
        )
        guard effectiveVolume > 0 else { return }

        if !bypassThrottle, isThrottled(effect) {
            return
        }

        lastPlayDates[effect] = Date()
        configureAudioSessionIfNeeded()

        if let url = bundleURL(for: effect) {
            playBundled(url: url, volume: effectiveVolume, effect: effect)
        } else {
            playSystemFallback(for: effect)
        }
    }

    private func playCrtShutdownSequence(ignoresEnabled: Bool, bypassThrottle: Bool) {
        guard ignoresEnabled || BootPreferencesStore.isSoundEnabled else { return }

        let effectiveVolume = Self.effectiveVolume(
            globalVolume: BootPreferencesStore.soundVolume,
            gain: SoundEffect.crtShutdown.gainMultiplier
        )
        guard effectiveVolume > 0 else { return }

        if !bypassThrottle, isThrottled(.crtShutdown) {
            return
        }

        lastPlayDates[.crtShutdown] = Date()
        configureAudioSessionIfNeeded()

        crtShutdownTask?.cancel()
        crtShutdownTask = nil
        stopOverlappingPlayers()

        if let url = bundleURL(for: .crtShutdown) {
            playBundled(url: url, volume: effectiveVolume, effect: .crtShutdown)
            return
        }

        crtShutdownTask = Task {
            await playProceduralCrtShutdown(volume: effectiveVolume)
            crtShutdownTask = nil
        }
    }

    private func playProceduralCrtShutdown(volume: Float) async {
        defer { pruneFinishedOverlappingPlayers() }

        playGeneratedPCM(CrtShutdownPCM.descendingTone(duration: 0.55, volume: volume), allowOverlap: true)

        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { return }

        playGeneratedPCM(CrtShutdownPCM.electricalDischarge(duration: 0.22, volume: volume), allowOverlap: true)

        try? await Task.sleep(nanoseconds: 240_000_000)
        guard !Task.isCancelled else { return }

        playGeneratedPCM(CrtShutdownPCM.collapseClick(volume: volume), allowOverlap: true)
    }

    private static func effectiveVolume(globalVolume: Float, gain: Float) -> Float {
        min(max(globalVolume * gain, 0), 1)
    }

    private func isThrottled(_ effect: SoundEffect) -> Bool {
        guard let lastPlay = lastPlayDates[effect] else { return false }
        return Date().timeIntervalSince(lastPlay) < effect.minimumPlayInterval
    }

    private func configureAudioSessionIfNeeded() {
        guard !didConfigureSession else { return }
        didConfigureSession = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func bundleURL(for effect: SoundEffect) -> URL? {
        for ext in effect.supportedExtensions {
            if let url = Bundle.main.url(forResource: effect.resourceName, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func playBundled(url: URL, volume: Float, effect: SoundEffect) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            assignActivePlayer(player)
            player.play()
        } catch {
            if effect == .crtShutdown {
                crtShutdownTask = Task {
                    await playProceduralCrtShutdown(volume: volume)
                    crtShutdownTask = nil
                }
            } else {
                playSystemFallback(for: effect)
            }
        }
    }

    private func playGeneratedPCM(_ data: Data?, allowOverlap: Bool) {
        guard let data else { return }
        do {
            let player = try AVAudioPlayer(data: data)
            player.volume = 1
            if allowOverlap {
                overlappingPlayers.append(player)
            } else {
                assignActivePlayer(player)
            }
            player.play()
        } catch {
            // Silent no-op — shutdown must continue.
        }
    }

    private func assignActivePlayer(_ player: AVAudioPlayer) {
        activePlayer?.stop()
        activePlayer = player
        player.prepareToPlay()
    }

    private func stopOverlappingPlayers() {
        for player in overlappingPlayers {
            player.stop()
        }
        overlappingPlayers.removeAll()
    }

    private func pruneFinishedOverlappingPlayers() {
        overlappingPlayers.removeAll { !$0.isPlaying }
    }

    private func playSystemFallback(for effect: SoundEffect) {
        guard effect != .crtShutdown, let soundID = effect.systemSoundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
    #else
    private func play(_ effect: SoundEffect, ignoresEnabled: Bool, bypassThrottle: Bool) {}
    private func playCrtShutdownSequence(ignoresEnabled: Bool, bypassThrottle: Bool) {}
    #endif
}

#if os(iOS)
private extension SoundEffect {
    var systemSoundID: SystemSoundID? {
        switch self {
        case .buttonTap, .toggle, .windowClose:
            1104
        case .windowOpen, .settingsSave:
            1103
        case .boot:
            1110
        case .defconWarning:
            1057
        case .midnightEvent:
            1016
        case .crtShutdown:
            nil
        }
    }
}
#endif
