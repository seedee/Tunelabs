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
    private let modelContext: ModelContext
    private let watcherManager = DirectoryWatcherManager()
    private var cancellables = Set<AnyCancellable>()
    let allowedExtensions = ["mp3", "wav", "m4a"]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        startDirectoryWatcher()
        loadInitialFiles()
    }
    
    private func startDirectoryWatcher() {
        watcherManager.startWatching { [weak self] in
            self?.processFiles()
        }
    }
    
    private func loadInitialFiles() {
        processFiles()
    }
    
    private func processFiles() {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            let audioFiles = files.filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
            
            // Get existing songs
            let existingURLs = try modelContext.fetch(FetchDescriptor<Song>()).map { $0.fileURL }
            
            // Add new files
            for fileURL in audioFiles where !existingURLs.contains(fileURL) {
                let song = Song(fileURL: fileURL)
                modelContext.insert(song)
                extractMetadata(for: song)
            }
            
            // Remove deleted files
            let songsToDelete = try modelContext.fetch(FetchDescriptor<Song>())
                .filter { !audioFiles.contains($0.fileURL) }
            songsToDelete.forEach { modelContext.delete($0) }
            
            try modelContext.save()
        } catch {
            print("Error processing files: \(error)")
        }
    }
    
    private func extractMetadata(for song: Song) {
        MetadataExtractor.extractMetadata(for: song.fileURL) { [weak self] metadata in
            song.title = metadata.title ?? song.fileURL.lastPathComponent
            song.artist = metadata.artist
            song.duration = metadata.duration
            song.artworkData = metadata.artworkData
            
            try? self?.modelContext.save()
        }
    }
}
