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
    @EnvironmentObject private var mainViewModel: MainViewModel
    @EnvironmentObject private var playerViewModel: PlayerViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack {
            SlidingTabView(
                selection: $mainViewModel.tabIndex,
                tabs: ["Library", "Song", "Settings"],
                font: .headline,
                animation: .easeInOut,
                
                selectionBarColor: themeManager.accentColor
            )
            
            Group {
                switch mainViewModel.tabIndex {
                case 0:
                    LibraryView()
                        .environmentObject(mainViewModel)
                        .environmentObject(playerViewModel)
                        .environmentObject(themeManager)
                case 1:
                    if let selectedSong = mainViewModel.selectedSong {
                        SongView(song: selectedSong)
                            .environmentObject(mainViewModel)
                            .environmentObject(playerViewModel)
                            .environmentObject(themeManager)
                    } else {
                        Text("Select a song!")
                            .frame(maxHeight: .infinity)
                    }
                case 2:
                    SettingsView()
                        .environmentObject(mainViewModel)
                        .environmentObject(playerViewModel)
                        .environmentObject(themeManager)
                default:
                    Text("Select a tab!")
                        .frame(maxHeight: .infinity)
                }
            }
            Spacer()
            PlayerView()
                .environmentObject(mainViewModel)
                .environmentObject(playerViewModel)
                .environmentObject(themeManager)
        }
    }
}

