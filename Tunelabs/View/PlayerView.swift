//
//  PlayerView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import AVKit

struct PlayerView: View {

    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                
                Text(mainViewModel.selectedSong?.fileURL.lastPathComponent ?? "No song selected")
                    .font(.body)
                    .padding([.top, .trailing, .leading], 20)
                
                Slider(value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.audioTime(to: $0) }
                ), in: 0...viewModel.totalTime)
                .padding([.trailing, .leading], 20)
                
                HStack {
                    Text(viewModel.timeString(time: viewModel.currentTime))
                        .frame(minWidth: 32)
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
                        .frame(minWidth: 32)
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
            }
        }
        .onChange(of: mainViewModel.selectedSong) { _, newSong in
            viewModel.handleNewFile(newSong?.fileURL)
        }
    }
}

/*#Preview {
    PlayerView()
}*/
