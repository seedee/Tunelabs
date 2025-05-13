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
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var songs: [Song]
    
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
                    get: { playerViewModel.currentTime },
                    set: { playerViewModel.audioTime(to: $0) }
                ), in: 0...max(playerViewModel.totalTime, 0.1))
                .padding([.trailing, .leading], 20)
                .id("\(playerViewModel.currentTime)")
                
                HStack {
                    Text(playerViewModel.timeString(time: playerViewModel.currentTime))
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
                        print("Play/pause")
                        withAnimation {
                            playerViewModel.isPlaying.toggle()
                            playerViewModel.isPlaying
                                ? playerViewModel.playAudio()
                                : playerViewModel.stopAudio()
                        }
                    } label: {
                        ZStack {
                            Image(systemName: "pause.fill")
                                .resizable()
                                .frame(width: 48, height: 48, alignment: .center)
                                .scaleEffect(playerViewModel.isPlaying ? 1 : 0)
                                .opacity(playerViewModel.isPlaying ? 1 : 0)
                                .animation(.easeInOut, value: playerViewModel.isPlaying)
                            
                            Image(systemName: "play.fill")
                                .resizable()
                                .frame(width: 48, height: 48, alignment: .center)
                                .scaleEffect(playerViewModel.isPlaying ? 0 : 1)
                                .opacity(playerViewModel.isPlaying ? 0 : 1)
                                .animation(.easeInOut, value: playerViewModel.isPlaying)
                        }
                    }
                    .disabled(mainViewModel.selectedSong == nil)
                    .onReceive(playerViewModel.$isPlaying) { _ in
                        
                    }
                    // Add an additional listener for time updates
                    .id(playerViewModel.isPlaying) // Force view refresh when playing state changes
                   
                    
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
                    
                    Text(playerViewModel.timeString(time: playerViewModel.totalTime))
                        .frame(minWidth: 32)
                }
                .font(.caption)
                .padding([.trailing, .leading], 20)
                .padding(.bottom, 8)
            }
        }
        .onChange(of: mainViewModel.selectedSong) { _, newSong in
            playerViewModel.handleNewFile(newSong?.fileURL)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Song.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = MainViewModel(modelContext: container.mainContext)
    return PlayerView()
        .environmentObject(viewModel)
}
