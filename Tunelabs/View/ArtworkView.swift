//
//  ArtworkView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI

struct ArtworkView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    let fileURL: URL?
    
    var body: some View {
        Group {
            if let url = fileURL {
                if let image = mainViewModel.audioArtworkCache[url] {
                    Image(uiImage: image)
                        .resizable()
                } else {
                    defaultArtworkView
                }
            } else {
                defaultArtworkView
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
    
    private var defaultArtworkView: some View {
        ZStack {
            Rectangle()
                .fill(.bar)
            GeometryReader { geometry in
                Image(systemName: "music.note.list")
                    .resizable()
                    .frame(width: geometry.size.width * 0.5, height: geometry.size.height * 0.5)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .shadow(color: .secondary.opacity(0.5), radius: 1, x: 2, y: 2)
            }
        }
    }
}

/*#Preview {
    ArtworkView()
}
*/
