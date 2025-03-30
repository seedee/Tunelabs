//
//  MainViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    
    @Published var selectedAudioFile: URL?
    @Published var audioFiles: [URL] = []
    @Published private(set) var audioArtworkCache: [URL: UIImage] = [:]
    @Published var tabIndex: Int = 0
    private let watcherManager = DirectoryWatcherManager()
    private var cancellables = Set<AnyCancellable>()
    let allowedExtensions = ["mp3", "wav", "m4a"]
    
    init() {
        watcherManager.startWatching { [weak self] in
            self?.loadFiles()
        }
        loadFiles()
    }
    
    deinit {
        watcherManager.stopWatching()
    }
    
    func loadFiles() {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            audioFiles = files.filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    func loadArtwork(for url: URL) {
        guard !audioArtworkCache.keys.contains(url) else { return }
        
        MetadataExtractor.getArtwork(for: url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.audioArtworkCache[url] = image
            }
            .store(in: &cancellables)
    }
}
