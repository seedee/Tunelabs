//
//  MainViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import SwiftUI
import SwiftData
import Combine

@MainActor
class MainViewModel: ObservableObject {
    
    @Published var selectedSong: Song?
    @Published var tabIndex: Int = 0
    @Query private var songs: [Song]
    private let modelContext: ModelContext
    private let watcherManager = DirectoryWatcherManager()
    let allowedExtensions = ["mp3", "wav", "m4a"]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        startDirectoryWatcher()
        processFiles()
    }
    
    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error)")
        }
    }
    
    func rollbackContext() {
        modelContext.rollback()
    }
    
    func updateSongURL(from oldURL: URL, to newURL: URL) {
        guard let song = songs.first(where: { $0.fileURL == oldURL }) else { return }
        song.fileURL = newURL
        saveContext()
    }
    
    private func startDirectoryWatcher() {
        watcherManager.startWatching { [weak self] in
            self?.processFiles()
        }
    }
    
    private func processFiles() {
        Task {
            guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
                let audioFiles = files.filter { self.allowedExtensions.contains($0.pathExtension.lowercased()) }
                
                // Get existing songs
                let existingSongs = try self.modelContext.fetch(FetchDescriptor<Song>())
                
                // Add new files
                for fileURL in audioFiles where !existingSongs.contains(where: { $0.fileURL == fileURL }) {
                    let metadata = await MetadataHandler.readMetadata(from: fileURL)
                    let song = Song(
                        fileURL: fileURL,
                        artwork: metadata.artwork,
                        title: metadata.title,
                        artist: metadata.artist,
                        duration: metadata.duration
                    )
                    self.modelContext.insert(song)
                }
                
                // Remove deleted files
                for song in existingSongs where !audioFiles.contains(song.fileURL) {
                    self.modelContext.delete(song)
                }
                
                try self.modelContext.save()
            } catch {
                print("File processing error: \(error)")
            }
        }
    }
}
