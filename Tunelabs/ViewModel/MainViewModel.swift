//
//  MainViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation
import Combine

class MainViewModel: ObservableObject {
    
    @Published var selectedAudioFile: URL?
    @Published var audioFiles: [URL] = []
    @Published var tabIndex: Int = 0
    let allowedExtensions = ["mp3", "wav", "m4a"]
    private let watcherManager = DirectoryWatcherManager()
    
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
}
