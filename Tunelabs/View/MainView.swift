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
            SlidingTabView(
                selection: $viewModel.tabIndex,
                tabs: ["Library", "Song", "Settings"],
                animation: .easeInOut,
                inactiveAccentColor: .primary
            )
            
            Group {
                switch viewModel.tabIndex {
                case 0:
                    LibraryView()
                case 1:
                    SongView()
                case 2:
                    Text("Settings")
                        .frame(maxHeight: .infinity)
                default:
                    Text("Choose a tab!")
                        .frame(maxHeight: .infinity)
                }
            }
            Spacer()
            PlayerView()
        }
        .environmentObject(viewModel)
    }
}

#Preview {
    MainView()
        .environmentObject(MainViewModel())
}
