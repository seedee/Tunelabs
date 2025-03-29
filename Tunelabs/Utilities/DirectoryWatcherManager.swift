//
//  DirectoryWatcherManager.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation

class DirectoryWatcherManager: ObservableObject {
    private var directoryWatcher: DirectoryWatcher?
    
    func startWatching(completion: @escaping () -> Void) {
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        directoryWatcher = DirectoryWatcher(watchFolder: docsURL)
        directoryWatcher?.onChange = { [weak self] in
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func stopWatching() {
        directoryWatcher = nil
    }
}
