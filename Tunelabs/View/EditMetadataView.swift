//
//  EditMetadataView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 28/04/2025.
//

import SwiftUI
import SwiftData

private struct EditableSong {
    var title: String?
    var artist: String?
    var artwork: Data?
}

struct EditMetadataView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var editableSong: EditableSong
    @State private var showConfirmDialog = false
    @State private var errorMessage: String?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Error"
    
    // Local state for UI binding
    @State private var localPitch: Float
    @State private var localSpeed: Float
    
    let song: Song
    
    init(song: Song) {
        _editableSong = State(initialValue: EditableSong(
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
        NavigationStack {
            Form {
                metadataSection
                artworkSection
                errorSection
            }
            .navigationTitle("Edit Metadata")
            .toolbar { toolbarItems }
            .confirmationDialog("Confirm Changes", isPresented: $showConfirmDialog) {
                confirmationButtons
            }
        }
    }
    
    private var metadataSection: some View {
        Section("Track Information") {
            TextField("Song Title", text: titleBinding)
            TextField("Artist Name", text: artistBinding)
        }
    }
    
    private var artworkSection: some View {
        Section("Artwork") {
            if let data = editableSong.artwork, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
            } else {
                Text("No artwork available")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var errorSection: some View {
        Group {
            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
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
                Button("Save") { showConfirmDialog = true }
            }
        }
    }
    
    private var confirmationButtons: some View {
        Group {
            Button("Cancel", role: .cancel) {}
            Button("Save Changes") { saveChanges() }
        }
    }
    
    private var titleBinding: Binding<String> {
        Binding(
            get: { editableSong.title ?? "" },
            set: { editableSong.title = $0.isEmpty ? nil : $0 }
        )
    }
    
    private var artistBinding: Binding<String> {
        Binding(
            get: { editableSong.artist ?? "" },
            set: { editableSong.artist = $0.isEmpty ? nil : $0 }
        )
    }
    
    private func saveChanges() {
        Task {
            do {
                guard let song = mainViewModel.selectedSong else { return }
                
                // Update model
                song.title = editableSong.title
                song.artist = editableSong.artist
                song.artwork = editableSong.artwork
                
                // Save to file
                try await MetadataHandler.writeMetadata(
                    to: song.fileURL,
                    title: song.title,
                    artist: song.artist,
                    artwork: song.artwork
                )
                
                // Persist changes
                mainViewModel.saveContext()
                dismiss()
            } catch {
                errorMessage = [
                    "Failed to save changes:",
                    error.localizedDescription,
                    "Original file might be read-only or in use."
                ].joined(separator: "\n")
                
                // Rollback changes
                mainViewModel.rollbackContext()
            }
        }
    }
}

/*#Preview {
    EditMetadataView()
}*/
