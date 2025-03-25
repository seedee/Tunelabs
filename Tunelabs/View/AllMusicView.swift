//
//  AllMusicView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI

import SwiftUI
import Combine

struct AllMusicView: View {
    
    let audioFiles: [URL]
    @Binding var selectedAudioFile: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            List(audioFiles, id: \.self) { fileURL in
                Text(fileURL.lastPathComponent)
                    .onTapGesture {
                        selectedAudioFile = fileURL
                    }
            }
            .listStyle(.plain)
            
            Spacer()
        }
    }
}

/*#Preview {
    AllMusicView()
}*/
