//
//  PlayerView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import AVKit

struct PlayerView: View {
    
    @StateObject private var viewModel = PlayerViewModel()
    @Binding var selectedAudioFile: URL?
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                
                Text(selectedAudioFile?.lastPathComponent ?? "No file selected")
                    .font(.footnote)
                    .padding([.top, .trailing, .leading], 20)
                
                Slider(value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.audioTime(to: $0) }
                ), in: 0...viewModel.totalTime)
                .padding([.trailing, .leading], 20)
                
                HStack {
                    Text(viewModel.timeString(time: viewModel.currentTime))
                    Spacer()
                    Button {
                        viewModel.isPlaying ? viewModel.stopAudio() : viewModel.playAudio()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    Spacer()
                    Text(viewModel.timeString(time: viewModel.totalTime))
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
            }
        }
        .onChange(of: selectedAudioFile) { _, newFile in
            viewModel.handleNewFile(newFile)
        }
    }
}
