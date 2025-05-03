//
//  DirectoryWatcherManager.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation

final class DirectoryWatcherManager {
    private var directoryWatcher: DirectoryWatcher?
    private var debounceWorkItem: DispatchWorkItem?
    private var isProcessing = false // Flag to prevent concurrent processing
    private let debounceInterval: TimeInterval = 1.0 // Up from 0.5 to better coalesce events
    
    func stopWatching() { // Lifecycle management
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
        directoryWatcher?.stopWatching()
        directoryWatcher = nil
        isProcessing = false
    }
    
    func startWatching(completion: @escaping () -> Void) { // Lifecycle management
        stopWatching()
        
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Error: Could not access documents directory")
            return
        }
        
        print("Setting up directory watcher for: \(docsURL.path)")
        
        // Create a dedicated background queue for file system events
        let watcherQueue = DispatchQueue(label: "com.tunelabs.directorywatcher", qos: .utility)
        
        directoryWatcher = DirectoryWatcher(watchFolder: docsURL, queue: watcherQueue)
        directoryWatcher?.onChange = { [weak self] in
            self?.handleDirectoryChange(completion: completion)
        }
        
        // Start the watcher after setup
        directoryWatcher?.startWatching()
    }
    
    private func handleDirectoryChange(completion: @escaping () -> Void) {
        // Cancel any pending work
        debounceWorkItem?.cancel()
        
        // Create a new debounce work item
        // Uses DispatchWorkItem instead of Timer for more reliable debouncing
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isProcessing else { return }
            
            // Set flag to prevent concurrent processing
            self.isProcessing = true
            
            print("Directory change detected - processing files...")
            DispatchQueue.main.async {
                // Execute the callback on the main thread
                completion()
                
                // Reset the processing flag after a delay to avoid rapid consecutive calls
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isProcessing = false
                }
            }
        }
        
        // Replace the old work item
        debounceWorkItem = workItem
        
        // Schedule the new work item with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
