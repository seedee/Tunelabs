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
    var onChange: (() -> Void)?
    
    init?(watchFolder: URL) {
        fileDescriptor = open(watchFolder.path, O_EVTONLY)
        guard fileDescriptor != -1 else { return nil }
        
        dispatchSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )
        
        dispatchSource?.setEventHandler { [weak self] in
            self?.onChange?()
        }
        
        dispatchSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.fileDescriptor)
            self.fileDescriptor = -1
            self.dispatchSource = nil
        }
        
        dispatchSource?.resume()
    }
    
    deinit {
        dispatchSource?.cancel()
    }
}
