//
//  MainView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import SwiftData
import SlidingTabView

struct MainView: View {
    @EnvironmentObject private var viewModel: MainViewModel
    
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
                    if let selectedSong = viewModel.selectedSong {
                        SongView(song: selectedSong)
                    } else {
                        Text("Select a song!")
                            .frame(maxHeight: .infinity)
                    }
                case 2:
                    Text("Settings")
                        .frame(maxHeight: .infinity)
                default:
                    Text("Select a tab!")
                        .frame(maxHeight: .infinity)
                }
            }
            Spacer()
            PlayerView()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Song.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let viewModel = MainViewModel(modelContext: container.mainContext)
    return MainView()
        .environmentObject(viewModel)
}
