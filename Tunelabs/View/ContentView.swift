//
//  ContentView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var songs: [Song]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(songs) { song in
                    NavigationLink {
                        Text("Song at \(song.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        Text(song.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                    }
                }
                .onDelete(perform: deleteSongs)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addSong) {
                        Label("Add Song", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select a song")
        }
    }

    private func addSong() {
        withAnimation {
            let newItem = Song(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteSongs(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(songs[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Song.self, inMemory: true)
}
