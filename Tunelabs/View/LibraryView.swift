//
//  LibraryView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI
import Combine

struct LibraryView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        VStack {
            List(mainViewModel.audioFiles, id: \.self) { fileURL in
                HStack(spacing: 16) {
                    ArtworkView(fileURL: fileURL)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text(fileURL.lastPathComponent)
                    Spacer()
                }
                .onTapGesture {
                    mainViewModel.selectedAudioFile = fileURL
                }
                .onAppear {
                    mainViewModel.loadArtwork(for: fileURL)
                }
            }
            .listStyle(.plain)
            Spacer()
        }
    }
}

/*Preview {
    LibraryView()
}*/
