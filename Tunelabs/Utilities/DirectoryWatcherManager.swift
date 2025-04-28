//
//  DirectoryWatcherManager.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation

final class DirectoryWatcherManager {
    private var directoryWatcher: DirectoryWatcher?
    private var debounceTimer: Timer?
    
    func startWatching(completion: @escaping () -> Void) {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        directoryWatcher = DirectoryWatcher(watchFolder: docsURL)
        directoryWatcher?.onChange = { [weak self] in
            // Debounce to prevent multiple rapid calls
            // Only one file processing call within a short time frame
            // Prevents multiple simultaneous directory change events
            self?.debounceTimer?.invalidate()
            self?.debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                guard self != nil else { return }
                DispatchQueue.main.async(execute: completion)
            }
        }
    }
    
    func stopWatching() {
        directoryWatcher = nil
    }
}
