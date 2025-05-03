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
    @StateObject private var viewModel = AudioEditorViewModel()
    @State private var showConfirmDialog = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    let song: Song
    
    var body: some View {
        NavigationStack {
            Form {
                effectsSection
                playbackSection
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
            .disabled(viewModel.isProcessing)
            .overlay {
                if viewModel.isProcessing {
                    ProgressView("Processing audio...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
            }
            .onAppear {
                loadAudio()
            }
            .onDisappear {
                viewModel.previewPlayer.stop()
            }
        }
    }
    
    private func loadAudio() {
        do {
            try viewModel.loadAudio(url: song.fileURL)
        } catch {
            alertTitle = "Audio Load Error"
            alertMessage = "Failed to load audio: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private var effectsSection: some View {
        Section("Audio Effects") {
            VStack(alignment: .leading) {
                HStack {
                    Text("Pitch")
                    Spacer()
                    Text("\(Int(viewModel.pitch)) semitones")
                }
                Slider(value: $viewModel.pitch, in: -12...12, step: 1)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading) {
                HStack {
                    Text("Speed")
                    Spacer()
                    Text(String(format: "%.2fx", viewModel.speed))
                }
                Slider(value: $viewModel.speed, in: 0.5...2.0, step: 0.1)
            }
            .padding(.vertical, 4)
            
            Button("Reset to Default") {
                viewModel.resetParameters()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var playbackSection: some View {
        Section("Preview") {
            HStack {
                Button {
                    if viewModel.previewPlayer.isPlaying {
                        viewModel.previewPlayer.pause()
                    } else {
                        viewModel.previewPlayer.play()
                    }
                } label: {
                    Image(systemName: viewModel.previewPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .padding(.horizontal, 8)
                }
                
                Button {
                    viewModel.previewPlayer.stop()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .padding(.horizontal, 8)
                }
                
                Spacer()
                
                Text(formatTime(viewModel.previewPlayer.currentTime))
                Text(" / ")
                Text(formatTime(viewModel.previewPlayer.duration))
            }
            .padding(.vertical, 8)
        }
    }
    
    private var infoSection: some View {
        Section("Info") {
            Text("Adjust effects in real-time without changing the original file. Use \"Save As\" to create a new audio file with the effects applied.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var toolbarItems: some ToolbarContent {
        Group {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save As") {
                    showConfirmDialog = true
                }
                .disabled(viewModel.isProcessing)
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
        // Stop playback before processing
        viewModel.previewPlayer.stop()
        
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
                
                // Process audio with timeout - explicitly declare as optional URL
                let processedURL: URL? = try await withThrowingTaskGroup(of: URL?.self) { group in
                    // Audio processing task
                    group.addTask {
                        do {
                            return try await viewModel.processAudioAsync(url: song.fileURL)
                        } catch {
                            await MainActor.run {
                                alertTitle = "Processing Error"
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                            return nil
                        }
                    }
                    
                    // Timeout task
                    group.addTask {
                        try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                        await MainActor.run {
                            if viewModel.isProcessing {
                                viewModel.isProcessing = false
                                alertTitle = "Processing Timeout"
                                alertMessage = "Audio processing is taking too long and has been cancelled."
                                showingAlert = true
                            }
                        }
                        return nil
                    }
                    
                    for try await result in group {
                        if let url = result {
                            group.cancelAll()
                            return url
                        }
                    }
                    
                    return nil // Return nil instead of throwing to match return type
                }
                
                // Safely unwrap processedURL
                guard let processedURL = processedURL else {
                    throw ProcessingError.cancelled
                }
                
                // Generate unique filename with timestamp
                let timestamp = Int(Date().timeIntervalSince1970)
                let newFilename = generateProcessedFilename(
                    for: song,
                    pitch: viewModel.pitch,
                    speed: viewModel.speed,
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
            } catch ProcessingError.cancelled {
                // Already handled in the task group
                await MainActor.run {
                    alertTitle = "Processing Cancelled"
                    alertMessage = "Audio processing was cancelled."
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    let song = Song(fileURL: URL(string: "file:///sample.mp3")!)
    return EditAudioView(song: song)
        .environmentObject(MainViewModel(modelContext: try! ModelContainer(for: Song.self).mainContext))
}
