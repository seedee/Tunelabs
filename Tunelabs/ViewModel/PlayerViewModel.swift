//
//  PlayerViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation
import AVKit
import Combine

class PlayerViewModel: ObservableObject {
    
    @Published var isPlaying = false
    @Published var totalTime: TimeInterval = 0.0
    @Published var currentTime: TimeInterval = 0.0
    private var timer: AnyCancellable?
    // Audio engine components
    private var engine: AVAudioEngine = AVAudioEngine()
    private var playerNode: AVAudioPlayerNode = AVAudioPlayerNode()
    private var pitchControl: AVAudioUnitTimePitch = AVAudioUnitTimePitch()
    private var audioFile: AVAudioFile?
    private var buffer: AVAudioPCMBuffer?
    private var currentURL: URL?
    
    // Effect parameters
    @Published var pitch: Float = 0.0 {
        didSet { if engine.isRunning { updateEffects() } }
    }
    @Published var speed: Float = 1.0 {
        didSet { if engine.isRunning { updateEffects() } }
    }
    
    // Store original values for cancellation
    private var originalPitch: Float = 0.0
    private var originalSpeed: Float = 1.0
    
    init() {
        setupAudioEngine()
    }
    
    deinit {
        timer?.cancel()
        cleanupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // Configure audio engine
        engine.attach(playerNode)
        engine.attach(pitchControl)
        
        // Connect nodes
        engine.connect(playerNode, to: pitchControl, format: nil)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
        
        // Set initial effect values
        updateEffects()
        
        // Prepare engine
        engine.prepare()
    }
    
    private func cleanupAudioEngine() {
        if engine.isRunning {
            playerNode.stop()
            engine.stop()
        }
    }
    
    private func updateEffects() {
        pitchControl.pitch = pitch * 100
        pitchControl.rate = speed
    }
    
    func beginEditingSession() {
        // Store original values to enable cancellation
        originalPitch = pitch
        originalSpeed = speed
        print("Starting edit session with pitch: \(pitch), speed: \(speed)")
    }
    
    func cancelEditing() {
        // Restore original values
        pitch = originalPitch
        speed = originalSpeed
        print("Cancelled editing, restored pitch: \(pitch), speed: \(speed)")
    }
    
    // React to file changes
    func handleNewFile(_ url: URL?) {
        guard let url = url else {
            resetPlayer()
            return
        }
        loadAudio(with: url)
        playAudio()
    }
    
    private func loadAudio(with url: URL) {
        stopAudio()
        currentURL = url
        
        do {
            // Load audio file
            audioFile = try AVAudioFile(forReading: url)
            guard let file = audioFile else { return }
            
            // Set duration
            totalTime = Double(file.length) / file.processingFormat.sampleRate
            currentTime = 0.0
            
            // Create buffer for playback
            buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: AVAudioFrameCount(file.length)
            )
            
            // Read file into buffer
            try file.read(into: buffer!)
            
            print("Audio loaded: \(url.lastPathComponent), duration: \(totalTime)s")
        } catch {
            print("Error loading audio: \(error.localizedDescription)")
        }
    }
    
    func playAudio() {
        guard let buffer = buffer else { return }
        
        // Start engine if needed
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Error starting audio engine: \(error.localizedDescription)")
                return
            }
        }
        
        updateEffects() //Apply before playback starts
        
        // Configure player noed
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: .interruptsAtLoop)
        playerNode.play()
        
        isPlaying = true
        startTimer()
        print("Started playback with effects - pitch: \(pitch), speed: \(speed)")
    }
    
    func stopAudio() {
        playerNode.stop()
        isPlaying = false
        timer?.cancel()
    }
    
    func resetPlayer() {
        stopAudio()
        audioFile = nil
        buffer = nil
        currentURL = nil
        totalTime = 0.0
        currentTime = 0.0
        isPlaying = false
        timer?.cancel()
    }
    
    func audioTime(to time: TimeInterval) {
        currentTime = time
        
        // Only restart playback if we need to seek
        guard let buffer = buffer else { return }
        
        let wasPlaying = isPlaying
        playerNode.stop()
        
        // Just reschedule the entire buffer and update the display time
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        
        // Resume playback if it was playing
        if wasPlaying {
            playerNode.play()
        }
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgress()
            }
    }
    
    private func updateProgress() {
        guard let file = audioFile, engine.isRunning else { return }
        
        // If node time is available, use it for precise timing
        if let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
            let sampleRate = file.processingFormat.sampleRate
            currentTime = Double(playerTime.sampleTime) / sampleRate
        }
        
        // Check if playback has stopped
        if !playerNode.isPlaying {
            isPlaying = false
            timer?.cancel()
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minute, seconds)
    }
}
