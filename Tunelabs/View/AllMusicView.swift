//
//  AllMusicView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import Combine

struct AllMusicView: View {
    
    @StateObject private var viewModel = AllMusicViewModel()
    @Binding var selectedAudioFile: URL?
    let audioFiles: [URL]
    
    var body: some View {
        VStack {
            List(audioFiles, id: \.self) { fileURL in
                HStack(spacing: 16) {
                    coverArtView(for: fileURL)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(fileURL.lastPathComponent)
                    Spacer()
                }
                .onTapGesture {
                    selectedAudioFile = fileURL
                }
                .onAppear {
                    viewModel.loadCoverArt(for: fileURL)
                }
            }
            .listStyle(.plain)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func coverArtView(for url: URL) -> some View {
        if let image = viewModel.coverArtCache[url] {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Rectangle()
                    .fill(.secondary)
                    .shadow(color: .primary.opacity(0.2), radius: 2, x: 1, y: 1)
                Image(systemName: "music.note.list")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
            }
        }
    }
}

/*Preview {
    AllMusicView()
}*/
