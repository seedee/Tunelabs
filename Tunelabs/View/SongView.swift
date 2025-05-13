//
//  SongView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI
import SwiftData

enum StorageError: Error, LocalizedError {
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .insufficientSpace:
            return "Not enough storage space available"
        }
    }
}

private struct EditableSong {
    var fileURL: URL?
    var title: String?
    var artist: String?
    var artwork: Data?
}

struct SongView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var songs: [Song]
    
    @State private var showMetadataView = false
    @State private var editableSong: EditableSong
    @State private var showConfirmDialog = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    // Local state for UI binding
    @State private var localPitch: Float
    @State private var localSpeed: Float
    
    let song: Song
    
    init(song: Song) {
        _editableSong = State(initialValue: EditableSong(
            fileURL: song.fileURL,
            title: song.title,
            artist: song.artist,
            artwork: song.artwork
        ))
        self.song = song
        // Initialize with current player values to avoid jumps
        _localPitch = State(initialValue: 0)
        _localSpeed = State(initialValue: 1)
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    showMetadataView = true
                } label: {
                    Label("Metadata", systemImage: "pencil")
                }
                Spacer()
            }
            .disabled(mainViewModel.selectedSong == nil)
            Spacer()
            ArtworkView(song: mainViewModel.selectedSong)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.all)
            Spacer()
        }
        .sheet(isPresented: $showMetadataView) {
            if let song = mainViewModel.selectedSong {
                MetadataView(song: song)
                    .environmentObject(mainViewModel)
            }
        }
        
        VStack(alignment: .leading) {
            HStack {
                Text("Pitch")
                Spacer()
                Text("\(Int(localPitch)) semitones")
            }
            Slider(value: $localPitch, in: -12...12, step: 1)
                .onChange(of: localPitch) { _, newValue in
                    playerViewModel.pitch = newValue
                }
        }
        .padding()
        .onAppear {
            // Start an editing session and sync local values
            playerViewModel.beginEditingSession()
            localPitch = playerViewModel.pitch
            localSpeed = playerViewModel.speed
            print("SongView: localPitch: \(localPitch), localSpeed: \(localSpeed)")
        }
        VStack(alignment: .leading) {
            HStack {
                Text("Speed")
                Spacer()
                Text(String(format: "%.2fx", localSpeed))
            }
            Slider(value: $localSpeed, in: 0.0...2.0, step: 0.1)
                .onChange(of: localSpeed) { _, newValue in
                    playerViewModel.speed = newValue
                }
            
            
        }
        .padding()
        
        HStack {
            Spacer()
            Button(action: resetSliders) {
                Label("Reset", systemImage: "pencil")
            }
            Spacer()
            Button(action: saveNew) {
                Label("Save New", systemImage: "pencil")
            }
            Spacer()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }


        Text("Changes will be applied in real-time")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
    }
    
    private func resetSliders() {
        localPitch = 0
        localSpeed = 1
        playerViewModel.pitch = 0
        playerViewModel.speed = 1
    }
    
    private func saveNew() {
        print("Saving pitch: \(playerViewModel.pitch), speed: \(playerViewModel.speed)")

        let currentTime = playerViewModel.currentTime
        let wasPlaying = playerViewModel.isPlaying
        
        // Save audio with current effects
        Task {
            do {
                // Display processing indicator
                await MainActor.run {
                    alertTitle = ""
                    alertMessage = "Processing with pitch: \(Int(localPitch)), speed: \(String(format: "%.1fx", localSpeed))"
                    showingAlert = true
                }
                
                // Create a new audio editor for file processing
                let audioEditor = AudioEditor()
                
                // Process audio with current effect values
                let processedURL = try await audioEditor.processAudio(
                    url: song.fileURL,
                    pitch: localPitch,
                    speed: localSpeed
                )
                
                // Generate unique filename
                let timestamp = Int(Date().timeIntervalSince1970)
                let newFilename = "\(song.fileURL.deletingPathExtension().lastPathComponent)_p\(Int(localPitch))_s\(Int(localSpeed * 100))_\(timestamp)"
                
                // Check if we need to change the extension for MP3 files
                let fileExtension = song.fileURL.pathExtension.lowercased() == "mp3" ? "m4a" : song.fileURL.pathExtension
                let targetURL = song.fileURL.deletingLastPathComponent()
                    .appendingPathComponent(newFilename)
                    .appendingPathExtension(fileExtension)
                
                // Move processed file to target location
                let fileManager = FileManager.default
                
                if fileManager.fileExists(atPath: targetURL.path) {
                    try fileManager.removeItem(at: targetURL)
                }
                try fileManager.moveItem(at: processedURL, to: targetURL)
                
                // Force model context to save
                await MainActor.run {
                    do {
                        mainViewModel.saveContext()
                    } catch {
                        print("Error saving context: \(error)")
                    }
                }

                // Force refresh the library
                await mainViewModel.processFiles()
                let newSong = try await mainViewModel.findSongByURL(processedURL, targetURL.relativePath)
                

                // Show success message and guide user to Library tab
                await MainActor.run {
                    showingAlert = false // Dismiss processing alert
                    resetSliders()
                    mainViewModel.tabIndex = 0 // Library tab indexs
                    mainViewModel.tabIndex = 1
                    alertTitle = "Song Created"
                    alertMessage = "Your modified song has been saved as '\(newFilename).\(fileExtension)'. Go to the Library tab to play it."
                    showingAlert = true
                }
                
            } catch {
                await MainActor.run {
                    showingAlert = false
                    alertTitle = "Error"
                    alertMessage = "Failed to create modified song: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func saveProcessedAudio() {
        Task {
            do {
                // Check space
                let fileManager = FileManager.default
                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                
                let availableSpace = try documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
                    .volumeAvailableCapacityForImportantUsage ?? 0
                
                //Min 10MB
                guard availableSpace > 10_000_000 else {
                    throw StorageError.insufficientSpace
                }
                
                // Create a new audio editor for file processing
                let audioEditor = AudioEditor()
                
                // Get current effect values from the player
                let currentPitch = playerViewModel.pitch
                let currentSpeed = playerViewModel.speed
                
                // Process audio with the current effect values
                let processedURL = try await audioEditor.processAudio(
                    url: song.fileURL,
                    pitch: currentPitch,
                    speed: currentSpeed
                )
                
                // Generate unique filename with timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let newFilename = generateProcessedFilename(
                    for: song,
                    pitch: playerViewModel.pitch,
                    speed: playerViewModel.speed,
                    timestamp: timestamp
                )
                
                let targetURL = song.fileURL.deletingLastPathComponent()
                    .appendingPathComponent(newFilename)
                    .appendingPathExtension(song.fileURL.pathExtension)
                
                // Handle existing file
                if fileManager.fileExists(atPath: targetURL.path) {
                    try fileManager.removeItem(at: targetURL)
                }
                
                // Move processed file
                try fileManager.moveItem(at: processedURL, to: targetURL)
                
                // Update library
                await MainActor.run {
                    mainViewModel.processFiles()
                    dismiss()
                }
                
            } catch StorageError.insufficientSpace {
                await MainActor.run {
                    alertTitle = "Storage Error"
                    alertMessage = "Not enough storage space available to save the processed audio."
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertTitle = "File Error"
                    alertMessage = "Error saving processed file: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func generateProcessedFilename(for song: Song, pitch: Float, speed: Float, timestamp: Int) -> String {
        let baseName = song.fileURL.deletingPathExtension().lastPathComponent
        return "\(baseName)_pitch\(Int(pitch))s_speed\(Int(speed * 100))x_time\(timestamp)"
    }
}
