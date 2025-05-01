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
    let allowedExtensions = ["mp3", "wav", "m4a", "aiff", "aif"]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        startDirectoryWatcher()
        
        // Perform initial library refresh
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
    
    private func startDirectoryWatcher() {
        watcherManager.startWatching { [weak self] in
            self?.processFiles()
        }
    }
    
    func updateSongURL(from oldURL: URL, to newURL: URL) {
        guard let song = songs.first(where: { $0.fileURL == oldURL }) else { return }
        song.fileURL = newURL
        saveContext()
    }
    
    func processFiles() {
        Task {
            guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Error accessing documents directory")
                return
            }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
                let audioFiles = files.filter { self.allowedExtensions.contains($0.pathExtension.lowercased()) }
                
                print("Found \(audioFiles.count) audio files in documents directory")
                
                // Fetch existing songs with their file URLs
                let existingSongURLs = try modelContext.fetch(FetchDescriptor<Song>()).map { $0.fileURL }
                                
                // Track newly added songs to prevent multiple additions in the same session
                var addedSongURLs = Set<URL>()
                
                // Add new files to library
                for fileURL in audioFiles {
                    // Check if the song is already in the library or has been added in this session
                    if !existingSongURLs.contains(fileURL) && !addedSongURLs.contains(fileURL) {
                        print("Adding new song: \(fileURL.lastPathComponent)")
                        
                        let metadata = await MetadataHandler.readMetadata(from: fileURL)
                        let song = Song(
                            fileURL: fileURL,
                            artwork: metadata.artwork,
                            title: metadata.title,
                            artist: metadata.artist,
                            duration: metadata.duration
                        )
                        
                        modelContext.insert(song)
                        addedSongURLs.insert(fileURL)
                    } else {
                        print("Skipping already added song: \(fileURL.lastPathComponent)")
                    }
                }
                
                try modelContext.save()
                
            } catch {
                print("File processing error: \(error)")
            }
        }
    }
    
    func nextSong() {
        guard !songs.isEmpty else { return }
        
        if let currentSong = selectedSong, let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) {
            let nextIndex = (currentIndex + 1) % songs.count
            selectedSong = songs[nextIndex]
        } else {
            selectedSong = songs.first
        }
    }
    
    func previousSong() {
        guard !songs.isEmpty else { return }
        
        if let currentSong = selectedSong, let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) {
            let previousIndex = (currentIndex - 1 + songs.count) % songs.count
            selectedSong = songs[previousIndex]
        } else {
            selectedSong = songs.first
        }
    }
}
