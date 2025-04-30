//
//  PlayerView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import AVKit
import SwiftData

struct PlayerView: View {
    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some View {
        VStack {
            VStack {
                Divider()
                
                Text(
                    mainViewModel.selectedSong?.title ??
                    mainViewModel.selectedSong?.fileURL.lastPathComponent ??
                    "No song selected"
                )
                .font(.body)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding([.top, .trailing, .leading], 20)
                
                if let artist = mainViewModel.selectedSong?.artist {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding([.trailing, .leading], 20)
                }
                
                Slider(value: Binding(
                    get: { viewModel.currentTime },
                    set: { viewModel.audioTime(to: $0) }
                ), in: 0...max(viewModel.totalTime, 0.1))
                .padding([.trailing, .leading], 20)
                
                HStack {
                    Text(viewModel.timeString(time: viewModel.currentTime))
                        .frame(minWidth: 32)
                    Spacer()
                    
                    // Previous button
                    Button {
                        mainViewModel.previousSong()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    .padding(.horizontal, 10)
                    
                    // Play/Pause button
                    Button {
                        viewModel.isPlaying ? viewModel.stopAudio() : viewModel.playAudio()
                    } label: {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    
                    // Next button
                    Button {
                        mainViewModel.nextSong()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    .padding(.horizontal, 10)
                    
                    Spacer()
                    Text(viewModel.timeString(time: viewModel.totalTime))
                        .frame(minWidth: 32)
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: mainViewModel.selectedSong) { _, newSong in
            viewModel.handleNewFile(newSong?.fileURL)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Song.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = MainViewModel(modelContext: container.mainContext)
    return PlayerView()
        .environmentObject(viewModel)
}
