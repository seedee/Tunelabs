//
//  TunelabsApp.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import SwiftUI
//import SwiftData

@main
struct TunelabsApp: App {
    /*var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Song.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()*/
    
    init() {
        createInstructionsFile()
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        //.modelContainer(sharedModelContainer)
    }
    
    private func createInstructionsFile() {
        // Get Documents directory URL
        guard let docsDir = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            print("Error: Couldn't access Documents directory")
            return
        }
        
        // Create file URL
        let instructionsURL = docsDir.appendingPathComponent("Instructions.txt")
        
        // Check if file exists
        if !FileManager.default.fileExists(atPath: instructionsURL.path) {
            let content = "Put your music in this folder and it will appear in the music library!"
            
            do {
                try content.write(to: instructionsURL, atomically: true, encoding: .utf8)
                print("Instructions file created at: \(instructionsURL)")
            } catch {
                print("Error creating instructions file: \(error.localizedDescription)")
            }
        } else {
            print("Instructions file already exists at: \(instructionsURL)")
        }
    }
}
