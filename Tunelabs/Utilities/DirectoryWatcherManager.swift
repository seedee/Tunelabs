//
//  DirectoryWatcherManager.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation

final class DirectoryWatcherManager {
    private var directoryWatcher: DirectoryWatcher?
    
    // Keep [weak self] to prevent retain cycles
    func startWatching(completion: @escaping () -> Void) {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        directoryWatcher = DirectoryWatcher(watchFolder: docsURL)
        directoryWatcher?.onChange = { [weak self] in
            guard self != nil else { return } // Maintain weak reference
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    func stopWatching() {
        directoryWatcher = nil
    }
}
