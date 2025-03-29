//
//  MainView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import SlidingTabView

struct MainView: View {
    
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        VStack {
            SlidingTabView(selection: $viewModel.tabIndex, tabs: ["All Music", "Playlists", "Settings"], animation: .easeInOut, inactiveAccentColor: .secondary)
            
            //SlidingT
            if viewModel.tabIndex == 0 {
                AllMusicView(selectedAudioFile: $viewModel.selectedAudioFile, audioFiles: viewModel.audioFiles)
            }
            Spacer()
            PlayerView(selectedAudioFile: $viewModel.selectedAudioFile)
        }
    }
}

#Preview {
    MainView()
}
