//
//  ThemeManager.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 13/05/2025.
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var accentColor: Color {
        didSet {
            saveColor()
        }
    }
    
    private let colorKey = "userAccentColor"
    
    init() {
        // Load saved color or use default
        if let colorData = UserDefaults.standard.data(forKey: colorKey),
           let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            self.accentColor = Color(uiColor)
        } else {
            // Default to system blue if no saved color
            self.accentColor = .blue
        }
    }
    
    private func saveColor() {
        let uiColor = UIColor(accentColor)
        do {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            UserDefaults.standard.set(colorData, forKey: colorKey)
        } catch {
            print("Error saving color: \(error)")
        }
    }
}
