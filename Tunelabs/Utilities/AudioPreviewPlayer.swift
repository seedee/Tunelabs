//
//  AudioPreviewPlayer.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//

import Foundation
import AVFoundation

class AudioPreviewPlayer: ObservableObject {
    private var engine: AVAudioEngine
    private var player: AVAudioPlayerNode
    private var pitchControl: AVAudioUnitTimePitch
    private var file: AVAudioFile?
    private var buffer: AVAudioPCMBuffer?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    private var displayLink: CADisplayLink?
    
    init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        pitchControl = AVAudioUnitTimePitch()
        
        engine.attach(player)
        engine.attach(pitchControl)
        
        engine.connect(player, to: pitchControl, format: nil)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
        
        try? engine.start()
    }
    
    func loadAudio(url: URL) {
        stop()
        
        do {
            file = try AVAudioFile(forReading: url)
            guard let file = file else { return }
            
            duration = Double(file.length) / file.processingFormat.sampleRate
            
            // Load entire file into buffer for gapless looping
            buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                             frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func play() {
        guard let buffer = buffer else { return }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
        isPlaying = true
        
        startProgressTracking()
    }
    
    func stop() {
        player.stop()
        isPlaying = false
        currentTime = 0
        stopProgressTracking()
    }
    
    func pause() {
        player.pause()
        isPlaying = false
        stopProgressTracking()
    }
    
    func updateEffects(pitch: Float, speed: Float) {
        pitchControl.pitch = pitch
        pitchControl.rate = speed
    }
    
    private func startProgressTracking() {
        stopProgressTracking()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopProgressTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateProgress() {
        guard isPlaying, player.isPlaying, let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return
        }
        
        let sampleRate = file?.processingFormat.sampleRate ?? 44100
        currentTime = Double(playerTime.sampleTime) / sampleRate
        
        // Handle looping
        if let buffer = buffer {
            let bufferLength = Double(buffer.frameLength)
            currentTime = currentTime.truncatingRemainder(dividingBy: bufferLength / sampleRate)
        }
    }
    
    deinit {
        stop()
        engine.stop()
    }
}
