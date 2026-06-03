import Foundation

/// Procedural PCM helpers for the CRT shutdown fallback (no bundled asset).
enum CrtShutdownPCM {
    private static let sampleRate: Double = 44_100

    static func descendingTone(duration: TimeInterval, volume: Float) -> Data? {
        let frameCount = max(1, Int(sampleRate * duration))
        var samples = [Float](repeating: 0, count: frameCount)
        let startFrequency = 2_900.0
        let endFrequency = 420.0

        for index in 0..<frameCount {
            let progress = Double(index) / Double(max(frameCount - 1, 1))
            let time = Double(index) / sampleRate
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            let envelope = pow(1.0 - progress, 1.35)
            samples[index] = Float(sin(2.0 * .pi * frequency * time) * envelope * 0.42 * Double(volume))
        }

        return wavData(samples: samples)
    }

    static func electricalDischarge(duration: TimeInterval, volume: Float) -> Data? {
        let frameCount = max(1, Int(sampleRate * duration))
        var samples = [Float](repeating: 0, count: frameCount)
        var rng = SeededRNG(seed: 0x7342)

        for index in 0..<frameCount {
            let progress = Double(index) / Double(max(frameCount - 1, 1))
            let envelope = pow(1.0 - progress, 1.1)
            let noise = (rng.nextUnit() * 2.0 - 1.0) * 0.55
            let crackle = sin(2.0 * .pi * 1_800.0 * Double(index) / sampleRate) * 0.12
            samples[index] = Float((noise + crackle) * envelope * 0.38 * Double(volume))
        }

        return wavData(samples: samples)
    }

    static func collapseClick(volume: Float) -> Data? {
        let duration = 0.045
        let frameCount = max(1, Int(sampleRate * duration))
        var samples = [Float](repeating: 0, count: frameCount)

        for index in 0..<frameCount {
            let progress = Double(index) / Double(max(frameCount - 1, 1))
            let time = Double(index) / sampleRate
            let envelope = exp(-progress * 14.0)
            let tick = sin(2.0 * .pi * 3_200.0 * time) * 0.7 + sin(2.0 * .pi * 1_100.0 * time) * 0.25
            samples[index] = Float(tick * envelope * 0.55 * Double(volume))
        }

        return wavData(samples: samples)
    }

    private static func wavData(samples: [Float]) -> Data? {
        guard !samples.isEmpty else { return nil }

        let channelCount: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * (bitsPerSample / 8)
        let dataSize = UInt32(samples.count * Int(bitsPerSample / 8))
        let chunkSize = 36 + dataSize

        var data = Data()
        data.reserveCapacity(Int(44 + dataSize))

        func appendString(_ value: String) { data.append(contentsOf: value.utf8) }
        func appendUInt32(_ value: UInt32) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }
        func appendUInt16(_ value: UInt16) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }

        appendString("RIFF")
        appendUInt32(chunkSize)
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(channelCount)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(byteRate)
        appendUInt16(blockAlign)
        appendUInt16(bitsPerSample)
        appendString("data")
        appendUInt32(dataSize)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let scaled = clamped * Float(Int16.max)
            let pcm = Int16(max(Float(Int16.min), min(Float(Int16.max), scaled)))
            var littleEndian = pcm.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }

        return data
    }

    private struct SeededRNG {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        mutating func nextUnit() -> Double {
            state = state &* 6_364_136_223_847_093_003 &+ 1_446_525_340_886_245_177
            let value = Double((state >> 11) & 0x1FFFF_FFFF) / Double(0x1FFFF_FFFF)
            return value
        }
    }
}
