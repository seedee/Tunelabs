//
//  TunelabsApp.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
import SwiftData

//Dependency injection timing
struct HelperRootView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var mainViewModel: MainViewModel
    @StateObject private var playerViewModel: PlayerViewModel
    
    init(modelContext: ModelContext) {
        _mainViewModel = StateObject(wrappedValue: MainViewModel(modelContext: modelContext))
        _playerViewModel = StateObject(wrappedValue: PlayerViewModel())
    }
    
    var body: some View {
        MainView()
            .environmentObject(mainViewModel)
            .environmentObject(playerViewModel)
    }
}

@main
struct TunelabsApp: App {
    let schema = Schema([
            Song.self,
    ])
    let modelConfiguration: ModelConfiguration
    let sharedModelContainer: ModelContainer
    
    init() {
        // Using schema
        self.modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            // Configure container with persistence
            sharedModelContainer = try ModelContainer(
                for: schema,
                configurations: modelConfiguration
            )
            
            // Creates only once
            instructionsFile()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            HelperRootView(modelContext: sharedModelContainer.mainContext)
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func instructionsFile() {
        guard let docsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            print("Error: Couldn't access Documents directory")
            return
        }
        
        let instructionsURL = docsDir.appendingPathComponent("Instructions.txt")
        
        if !FileManager.default.fileExists(atPath: instructionsURL.path) {
            let content = "Copy your tunes into this folder, they will appear in the music library"
            
            do {
                try content.write(to: instructionsURL, atomically: true, encoding: .utf8)
                print("Instructions file created: \(instructionsURL)")
            } catch {
                print("Error creating instructions file: \(error.localizedDescription)")
            }
        } else {
            print("Instructions file read: \(instructionsURL)")
        }
    }
}
