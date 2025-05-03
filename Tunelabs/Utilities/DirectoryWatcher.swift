//
//  DirectoryWatcher.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation

class DirectoryWatcher {
    private var fileDescriptor: CInt = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var dispatchQueue: DispatchQueue
    private var isWatching = false
    var onChange: (() -> Void)?
    
    init?(watchFolder: URL, queue: DispatchQueue = .main) {
        self.dispatchQueue = queue
        fileDescriptor = open(watchFolder.path, O_EVTONLY)
        
        guard fileDescriptor != -1 else {
            print("Failed to open directory for watching: \(watchFolder.path)")
            return nil
        }
    }
    
    func startWatching() {
        guard !isWatching, fileDescriptor != -1 else { return }
        
        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib, .link, .rename, .revoke],
            queue: dispatchQueue
        )
        
        dispatchSource?.setEventHandler { [weak self] in
            self?.onChange?()
        }
        
        dispatchSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.dispatchSource = nil
            self.isWatching = false
        }
        
        dispatchSource?.resume()
        isWatching = true
        print("Directory watcher started")
    }
    
    func stopWatching() {
        guard isWatching else { return }
        dispatchSource?.cancel() // Will take care of cleanup
    }
        
    deinit {
            stopWatching()
    }
}
