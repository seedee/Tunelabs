//
//  EditAudioView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//

import SwiftUI

struct EditAudioView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewModel: MainViewModel
    @StateObject private var viewModel = AudioEditorViewModel()
    @State private var showConfirmDialog = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let song: Song
    
    var body: some View {
        NavigationStack {
            Form {
                effectsSection
                infoSection
            }
            .navigationTitle("Edit Audio")
            .toolbar { toolbarItems }
            .confirmationDialog("Apply Audio Effects", isPresented: $showConfirmDialog) {
                confirmationButtons
            } message: {
                Text("This will create a new version of the audio file with the applied effects.")
            }
            .alert("Processing Error", isPresented: $showingAlert) {
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
                Slider(value: $viewModel.speed, in: 0.5...2.0, step: 0.05)
            }
            .padding(.vertical, 4)
            
            Button("Reset to Default") {
                viewModel.resetParameters()
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var infoSection: some View {
        Section("Info") {
            Text("Changes will create a new audio file with the effects applied. The original file will remain unchanged.")
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
                Button("Apply") {
                    showConfirmDialog = true
                }
            }
        }
    }
    
    private var confirmationButtons: some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Apply Effects") { applyAudioEffects() }
        }
    }
    
    private func applyAudioEffects() {
        viewModel.processAudio(url: song.fileURL) { result in
            switch result {
            case .success(let processedURL):
                // Generate new filename with effect info
                let newFilename = generateProcessedFilename(for: song, pitch: viewModel.pitch, speed: viewModel.speed)
                let fileManager = FileManager.default
                let targetURL = song.fileURL.deletingLastPathComponent()
                    .appendingPathComponent(newFilename)
                    .appendingPathExtension(song.fileURL.pathExtension)
                
                do {
                    // If target already exists, remove it
                    if fileManager.fileExists(atPath: targetURL.path) {
                        try fileManager.removeItem(at: targetURL)
                    }
                    
                    // Move processed file to target location
                    try fileManager.moveItem(at: processedURL, to: targetURL)
                    
                    // Update library to include the new file
                    mainViewModel.processFiles()
                    
                    dismiss()
                } catch {
                    alertMessage = "Error saving processed file: \(error.localizedDescription)"
                    showingAlert = true
                }
                
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func generateProcessedFilename(for song: Song, pitch: Float, speed: Float) -> String {
        let baseName = song.fileURL.deletingPathExtension().lastPathComponent
        return "\(baseName)_p\(Int(pitch))_s\(Int(speed * 100))"
    }
}

#Preview {
    let song = Song(fileURL: URL(string: "file:///sample.mp3")!)
    return EditAudioView(song: song)
        .environmentObject(MainViewModel(modelContext: try! ModelContainer(for: Song.self).mainContext))
}
