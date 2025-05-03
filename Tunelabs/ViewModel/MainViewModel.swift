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
    private var initialScanComplete = false
    let allowedExtensions = ["mp3", "wav", "m4a", "aiff", "aif"]
    
    // Make playerViewModel accessible
    @Published var playerViewModel = PlayerViewModel()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        
        // Perform initial library refresh first
        Task {
            await performInitialScan()
            
            // Start watching for changes only after initial scan
            startDirectoryWatcher()
        }
    }
    
    private func performInitialScan() async {
        print("Performing initial library scan...")
        await scanLibrary()
        initialScanComplete = true
        print("Initial library scan complete")
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
        print("Starting directory watcher...")
        watcherManager.startWatching { [weak self] in
            guard let self = self, self.initialScanComplete else { return }
            
            print("Directory watcher triggered library scan")
            Task {
                await self.scanLibrary()
            }
        }
    }
    
    func updateSongURL(from oldURL: URL, to newURL: URL) {
        guard let song = songs.first(where: { $0.fileURL.path == oldURL.path }) else { return }
        song.fileURL = newURL
        
        // Update player if this was the selected song
        if song.id == selectedSong?.id {
            playerViewModel.handleNewFile(newURL)
        }
        saveContext()
    }
    
    // Call this method to manually refresh the library
    func processFiles() {
        Task {
            await scanLibrary()
        }
    }
    
    // The core scanning function, shared by, and handles both initial scan and watcher-triggered scans
    private func scanLibrary() async {
        print("Scanning library for changes...")
        
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error accessing documents directory")
            return
        }
        
        do {
            // Get all audio files in the documents directory
            let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            let audioFiles = files.filter { self.allowedExtensions.contains($0.pathExtension.lowercased()) }
            
            print("Found \(audioFiles.count) audio files in documents directory")
            
            // Create a set of paths for efficient lookup
            let libraryFilePaths = Set(audioFiles.map { $0.path })
            
            // Fetch all existing songs from the database
            let fetchDescriptor = FetchDescriptor<Song>()
            let existingSongs = try modelContext.fetch(fetchDescriptor)
            let existingSongPaths = Dictionary(uniqueKeysWithValues: existingSongs.map { ($0.fileURL.path, $0) })
            
            // Track changes for logging
            var addedCount = 0
            var removedCount = 0
            
            // Process new files
            for fileURL in audioFiles {
                let filePath = fileURL.path
                
                if existingSongPaths[filePath] == nil {
                    // This is a new file - add it to the library
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
                    addedCount += 1
                }
            }
            
            // Remove songs that no longer exist in the file system
            for (path, song) in existingSongPaths {
                if !libraryFilePaths.contains(path) {
                    print("Removing deleted song: \(song.fileURL.lastPathComponent)")
                    modelContext.delete(song)
                    removedCount += 1
                }
            }
            
            // Save changes if any were made
            if addedCount > 0 || removedCount > 0 {
                print("Library changes: \(addedCount) songs added, \(removedCount) songs removed")
                try modelContext.save()
            } else {
                print("No changes detected in library")
            }
            
        } catch {
            print("Library scan error: \(error)")
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
