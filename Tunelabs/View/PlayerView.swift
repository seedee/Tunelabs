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
                    get: { mainViewModel.playerViewModel.currentTime },
                    set: { mainViewModel.playerViewModel.audioTime(to: $0) }
                ), in: 0...max(mainViewModel.playerViewModel.totalTime, 0.1))
                .padding([.trailing, .leading], 20)
                
                HStack {
                    Text(mainViewModel.playerViewModel.timeString(time: mainViewModel.playerViewModel.currentTime))
                        .frame(minWidth: 32)
                    Spacer()
                    Spacer()
                    // Previous button
                    Button {
                        mainViewModel.previousSong()
                    } label: {
                        Image(systemName: "backward.fill")
                            .resizable()
                            .frame(width: 36, height: 24, alignment: .leading)
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    // Play/Pause button
                    Button {
                        DispatchQueue.main.async {
                            mainViewModel.playerViewModel.isPlaying ? mainViewModel.playerViewModel.stopAudio() : mainViewModel.playerViewModel.playAudio()
                        }
                    } label: {
                        Image(systemName: mainViewModel.playerViewModel.isPlaying ? "pause.fill" : "play.fill")
                            .resizable()
                            .frame(width: 48, height: 48, alignment: .center)
                    }
                    .onReceive(mainViewModel.playerViewModel.$isPlaying) { _ in
                        DispatchQueue.main.async {}
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    
                    Spacer()
                    
                    // Next button
                    Button {
                        mainViewModel.nextSong()
                    } label: {
                        Image(systemName: "forward.fill")
                            .resizable()
                            .frame(width: 36, height: 24, alignment: .trailing)
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    .padding(.horizontal, 10)
                    Spacer()
                    Spacer()
                    Text(mainViewModel.playerViewModel.timeString(time: mainViewModel.playerViewModel.totalTime))
                        .frame(minWidth: 32)
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: mainViewModel.selectedSong) { _, newSong in
            mainViewModel.playerViewModel.handleNewFile(newSong?.fileURL)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Song.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = MainViewModel(modelContext: container.mainContext)
    return PlayerView()
        .environmentObject(viewModel)
}
