//
//  SongView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/03/2025.
//

import SwiftUI

struct SongView: View {
    
    @EnvironmentObject private var mainViewModel: MainViewModel
    
    var body: some View {
        VStack {
            Spacer()
            ArtworkView(fileURL: mainViewModel.selectedAudioFile)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.all)
            Spacer()
        }
    }
}

/*#Preview {
    SongView()
}*/
