import Foundation
import AVFoundation

/// Manages audio playback for the PokéWalker buzzer
class AudioManager {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var mixer: AVAudioMixerNode?
    
    // Audio format matching the emulator's output
    private let sampleRate: Double = 32000
    private let channels: AVAudioChannelCount = 1
    
    // Square wave generation
    private var phase: Float = 0.0
    private var currentFrequency: Float = 0.0
    private var isPlaying: Bool = false
    
    init() {
        setupAudio()
    }
    
    deinit {
        stopAudio()
    }
    
    private func setupAudio() {
        audioEngine = AVAudioEngine()
        mixer = AVAudioMixerNode()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine,
              let mixer = mixer,
              let playerNode = playerNode else { return }
        
        let audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels
        )!
        
        engine.attach(mixer)
        engine.attach(playerNode)
        
        engine.connect(playerNode, to: mixer, format: audioFormat)
        engine.connect(mixer, to: engine.mainMixerNode, format: audioFormat)
        
        mixer.outputVolume = 0.5
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    /// Play a tone at the given frequency (called from emulator thread)
    func playTone(frequency: Float, fullVolume: Bool) {
        guard frequency > 0 else {
            isPlaying = false
            return
        }
        
        currentFrequency = frequency
        isPlaying = true
        
        // Update mixer volume based on fullVolume flag
        mixer?.outputVolume = fullVolume ? 0.8 : 0.4
    }
    
    /// Generate square wave samples for the audio buffer
    private func generateSamples(buffer: UnsafeMutableBufferPointer<Float>, count: Int) {
        let freq = currentFrequency
        guard freq > 0 && isPlaying else {
            buffer.initialize(repeating: 0, count: count)
            return
        }
        
        let phaseIncrement = Float(2.0 * .pi * freq / Float(sampleRate))
        
        for i in 0..<count {
            // Square wave: +1 for first half, -1 for second half
            let sample: Float = phase < .pi ? 1.0 : -1.0
            buffer[i] = sample * 0.3  // Reduce volume to avoid clipping
            phase += phaseIncrement
            if phase >= 2.0 * .pi {
                phase -= 2.0 * .pi
            }
        }
    }
    
    /// Stop all audio
    func stopAudio() {
        isPlaying = false
        currentFrequency = 0
        audioEngine?.stop()
    }
    
    /// Set master volume
    func setVolume(_ volume: Float) {
        mixer?.outputVolume = volume
    }
}

// MARK: - Audio Engine Scheduling

extension AudioManager {
    /// Schedule a buffer of audio samples for playback
    func scheduleBuffer(_ data: Data) {
        guard let playerNode = playerNode,
              let audioFormat = AVAudioFormat(
                standardFormatWithSampleRate: sampleRate,
                channels: channels
              ) else { return }
        
        let frameCount = AVAudioFrameCount(data.count / MemoryLayout<Float>.size)
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount) else { return }
        
        audioBuffer.frameLength = frameCount
        
        data.withUnsafeBytes { ptr in
            guard let floatPtr = ptr.baseAddress?.assumingMemoryBound(to: Float.self) else { return }
            audioBuffer.floatChannelData?[0]?.update(from: floatPtr, count: Int(frameCount))
        }
        
        playerNode.scheduleBuffer(audioBuffer)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
}
