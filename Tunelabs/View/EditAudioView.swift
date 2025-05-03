//  EditAudioView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//
        
import SwiftUI
import SwiftData

struct EditAudioView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showConfirmDialog = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    // Local state for UI binding
    @State private var localPitch: Float
    @State private var localSpeed: Float
    
    let song: Song
    
    init(song: Song) {
        self.song = song
        // Initialize with current player values to avoid jumps
        _localPitch = State(initialValue: 0)
        _localSpeed = State(initialValue: 1)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                effectsSection
                infoSection
            }
            .navigationTitle("Edit Audio")
            .toolbar { toolbarItems }
            .confirmationDialog("Save Audio with Effects", isPresented: $showConfirmDialog) {
                confirmationButtons
            } message: {
                Text("This will create a new version of the audio file with the applied effects.")
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                // Start an editing session and sync local values
                mainViewModel.playerViewModel.beginEditingSession()
                localPitch = mainViewModel.playerViewModel.pitch
                localSpeed = mainViewModel.playerViewModel.speed
                print("Edit view appeared, pitch: \(localPitch), speed: \(localSpeed)")
            }
        }
    }
    
    private var effectsSection: some View {
        Section("Audio Effects") {
            VStack(alignment: .leading) {
                HStack {
                    Text("Pitch")
                    Spacer()
                    Text("\(Int(localPitch)) semitones")
                }
                Slider(value: $localPitch, in: -12...12, step: 1)
                    .onChange(of: localPitch) { _, newValue in
                        mainViewModel.playerViewModel.pitch = newValue
                    }
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text(String(format: "%.2fx", localSpeed))
                }
                Slider(value: $localSpeed, in: 0.5...2.0, step: 0.1)
                    .onChange(of: localSpeed) { _, newValue in
                        mainViewModel.playerViewModel.speed = newValue
                    }
            }
            .padding(.vertical, 4)
            
            Button("Reset to Default") {
                localPitch = 0
                localSpeed = 1
                mainViewModel.playerViewModel.pitch = 0
                mainViewModel.playerViewModel.speed = 1
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var infoSection: some View {
        Section("Info") {
            Text("Changes are applied to the currently playing audio in real-time. \"Save As\" to create a new audio file with the effects applied, or \"Cancel\" to revert to the original sound.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    // Reset to original values
                    mainViewModel.playerViewModel.cancelEditing()
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save As") {
                    showConfirmDialog = true
                }
            }
        }
    }
    
    private var confirmationButtons: some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Save As New File") { saveProcessedAudio() }
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
                let currentPitch = mainViewModel.playerViewModel.pitch
                let currentSpeed = mainViewModel.playerViewModel.speed
                
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
                    pitch: mainViewModel.playerViewModel.pitch,
                    speed: mainViewModel.playerViewModel.speed,
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
        return "\(baseName)_p\(Int(pitch))_s\(Int(speed * 100))_\(timestamp)"
    }
}
