//
//  MainView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import SlidingTabView

struct MainView: View {
    
    @StateObject private var watcher = DirectoryWatcherManager()
    @State private var tabIndex = 0
    @State private var audioFiles: [URL] = []
    @State private var selectedAudioFile: URL?
    let allowedExtensions = ["mp3", "wav", "m4a"]
    
    var body: some View {
        
        
        VStack {
            SlidingTabView(selection: $tabIndex, tabs: ["All Music", "Playlists", "Settings"], animation: .easeInOut)
            
            if tabIndex == 0 {
                AllMusicView(audioFiles: audioFiles, selectedAudioFile: $selectedAudioFile)
            }
            Spacer()
            PlayerView(selectedAudioFile: $selectedAudioFile)
        }
        .onAppear {
            loadFiles()
            watcher.startWatching { self.loadFiles() }
        }
        .onDisappear {
            watcher.stopWatching()
        }
    }
    
    private func loadFiles() {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: docsDir, includingPropertiesForKeys: nil)
            audioFiles = files.filter { allowedExtensions.contains($0.pathExtension.lowercased()) }
        } catch {
            print("Error loading files: \(error)")
        }
    }
}

#Preview {
    MainView()
}

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
