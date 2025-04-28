//
//  LibraryView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]
    
    var body: some View {
        VStack {
            if songs.isEmpty {
                Spacer()
                VStack {
                    Text("Your song library is empty!")
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                    Text("Add your music by putting it into the Tunelabs folder in the Files app.")
                        .font(.body)
                        .padding(.horizontal, 60)
                }
                Spacer()
            }
            else {
                List(songs) { song in
                    HStack(spacing: 16) {
                        ArtworkView(song: song)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        VStack(alignment: .leading) {
                            Text(song.title ?? song.fileURL.lastPathComponent)
                                .font(.body)
                            if let artist = song.artist {
                                Text(artist)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .onTapGesture {
                    mainViewModel.selectedSong = song
                    }
                }
                .listStyle(.plain)
                Spacer()
            }
        }
    }
}

/*Preview {
    LibraryView()
}*/
