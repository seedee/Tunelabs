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
    private var player: AVAudioPlayer?
    private var timer: AnyCancellable?
    private var stopObserver: Any?
    
    deinit {
        timer?.cancel()
    }
    
    // React to file changes
    func handleNewFile(_ url: URL?) {
        guard let url = url else {
            resetPlayer()
            return
        }
        setupAudio(with: url)
        playAudio()
    }
    
    private func setupAudio(with url: URL) {
        stopAudio()
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            totalTime = player?.duration ?? 0.0
            currentTime = 0.0
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func playAudio() {
        player?.play()
        isPlaying = true
        startTimer()
    }
    
    func stopAudio() {
        player?.stop()
        isPlaying = false
        timer?.cancel()
    }
    
    func resetPlayer() {
        player = nil
        totalTime = 0.0
        currentTime = 0.0
        isPlaying = false
        timer?.cancel()
    }
    
    func audioTime(to time: TimeInterval) {
        player?.currentTime = time
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateProgress()
            }
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
        
        if !player.isPlaying {
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
