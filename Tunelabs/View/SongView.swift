//
//  SongView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI

struct SongView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    @State private var showMetadataEditor = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("Edit Audio", systemImage: "folder") {
                }
                Spacer()
                Button("Edit Metadata", systemImage: "pencil") {
                    showMetadataEditor = true
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
        .sheet(isPresented: $showMetadataEditor) {
            if let song = mainViewModel.selectedSong {
                EditMetadataView(song: song)
                    .environmentObject(mainViewModel)
            }
        }
    }
}

/*#Preview {
    SongView()
}*/
