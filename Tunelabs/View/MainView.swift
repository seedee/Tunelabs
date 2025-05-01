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
    
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: MainViewModel
    
    init() {
        // Create the view model with the model context from the environment
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: Song.self, configurations: config)
        _viewModel = StateObject(wrappedValue: MainViewModel(modelContext: container.mainContext))
    }
    
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
                    Text("Select a tab!")
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
}
