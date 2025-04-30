//
//  SongView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI
import SwiftData

struct SongView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showMetadataEditor = false
    @State private var showAudioEditor = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Edit Audio", systemImage: "waveform") {
                    showAudioEditor = true
                }
                Spacer()
                Button("Edit Metadata", systemImage: "pencil") {
                    showMetadataEditor = true
                }
                Spacer()
            }
            .disabled(mainViewModel.selectedSong == nil)
            Spacer()
            ArtworkView(song: mainViewModel.selectedSong)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.all)
            Spacer()
        }
        .sheet(isPresented: $showMetadataEditor) {
            if let song = mainViewModel.selectedSong {
                EditMetadataView(song: song)
                    .environmentObject(mainViewModel)
            }
        }
        .sheet(isPresented: $showAudioEditor) {
            if let song = mainViewModel.selectedSong {
                EditAudioView(song: song)
                    .environmentObject(mainViewModel)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Song.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = MainViewModel(modelContext: container.mainContext)
    return SongView()
        .environmentObject(viewModel)
}
