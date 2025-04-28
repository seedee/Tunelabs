//
//  ArtworkView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI

struct ArtworkView: View {
    
    let song: Song?
        
    var body: some View {
        if let song = song, let artworkData = song.artworkData, let image = UIImage(data: artworkData) {
            Image(uiImage: image)
                .resizable()
                .shadow(color: .secondary.opacity(0.2), radius: 2, x: 1, y: 1)
                .aspectRatio(1, contentMode: .fill)
        } else {
            defaultArtworkView
        }
    }
    
    private var defaultArtworkView: some View {
        ZStack {
            Rectangle()
                .fill(.bar)
                .shadow(color: .secondary.opacity(0.2), radius: 2, x: 1, y: 1)
                .aspectRatio(1, contentMode: .fit)
            GeometryReader { geometry in
                Image(systemName: "music.note.list")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
