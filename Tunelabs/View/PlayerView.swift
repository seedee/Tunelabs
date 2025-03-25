//
//  PlayerView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import AVKit

struct PlayerView: View {

    @State private var player: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var totalTime: TimeInterval = 0.0
    @State private var currentTime: TimeInterval = 0.0
    @Binding var selectedAudioFile: URL?
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                
                Text(selectedAudioFile?.lastPathComponent ?? "No file selected")
                    .font(.footnote)
                    .padding([.top, .trailing, .leading], 20)
                
                Slider(value: Binding(get: { currentTime }, set: { audioTime(to: $0) }), in: 0...totalTime)
                    .padding([.trailing, .leading], 20)
                
                HStack {
                    Text(timeString(time: currentTime))
                    Spacer()
                    Button {
                        isPlaying ? stopAudio() : playAudio()
                    } label: {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width:25, height: 25)
                    }
                    Spacer()
                    Text(timeString(time: totalTime))
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
            }
        }
        .onAppear {
            if let url = selectedAudioFile {
                setupAudio(with: url)
            }
        }
        .onChange(of: selectedAudioFile) { newURL in
            guard let newURL = newURL else {
                resetPlayer()
                return
            }
            setupAudio(with: newURL)
            playAudio()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            updateProgress()
        }
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
    
    private func playAudio() {
        player?.play()
        isPlaying = true
    }
    
    private func stopAudio() {
        player?.stop()
        isPlaying = false
    }
    
    private func resetPlayer() {
        player = nil
        totalTime = 0.0
        currentTime = 0.0
        isPlaying = false
    }
    
    private func updateProgress() {
        guard let player = player else { return }
        currentTime = player.currentTime
    }
    
    private func audioTime(to time: TimeInterval) {
        player?.currentTime = time
    }
    
    private func timeString(time: TimeInterval) -> String {
        let minute = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minute, seconds)
    }
}

/*#Preview {
    PlayerView()
}
*/
