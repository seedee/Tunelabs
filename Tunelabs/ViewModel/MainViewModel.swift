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
            guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            
            do {
                let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
                let audioFiles = files.filter { self.allowedExtensions.contains($0.pathExtension.lowercased()) }
                
                // Fetch all existing songs
                let existingSongs = try self.modelContext.fetch(FetchDescriptor<Song>())
                
                // Identify songs to remove (files no longer in documents)
                let songsToRemove = existingSongs.filter { song in
                    !audioFiles.contains(song.fileURL)
                }
                
                // Handle selected song removal
                if let selectedSong = selectedSong, songsToRemove.contains(where: { $0.fileURL == selectedSong.fileURL }) {
                    // If selected song is removed, clear selection
                    self.selectedSong = nil
                }
                
                // Remove songs that no longer exist in documents
                for song in songsToRemove {
                    self.modelContext.delete(song)
                }
                
                // Add new files not already in library
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
                
                try self.modelContext.save()
            } catch {
                print("File processing error: \(error)")
            }
        }
    }
    
    // MARK: - Song Navigation
    
    func nextSong() {
        guard !songs.isEmpty else { return }
        
        if let currentSong = selectedSong, let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) {
            // If we have a currently selected song, find its index and select the next one
            let nextIndex = (currentIndex + 1) % songs.count
            selectedSong = songs[nextIndex]
        } else {
            // If no song is selected or we can't find the current song, select the first one
            selectedSong = songs.first
        }
    }
    
    func previousSong() {
        guard !songs.isEmpty else { return }
        
        if let currentSong = selectedSong, let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) {
            // If we have a currently selected song, find its index and select the previous one
            let previousIndex = (currentIndex - 1 + songs.count) % songs.count
            selectedSong = songs[previousIndex]
        } else {
            // If no song is selected or we can't find the current song, select the first one
            selectedSong = songs.first
        }
    }
}
