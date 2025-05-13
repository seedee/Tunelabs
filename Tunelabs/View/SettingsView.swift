//
//  SettingsView.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 13/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Tunelabs")
                .font(.headline)
            Text("1.0")
                .font(.caption)
            Spacer()
            Text("Music player and editor")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        
        HStack(alignment: .center, spacing: 8) {
            Spacer()
            ColorPicker("Accent Color", selection: $themeManager.accentColor)
                .padding(.vertical, 8)
            Button("Reset") {
                themeManager.accentColor = .blue
            }
            Spacer()
        }
        .padding()
    }
}
