//
//  Song.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import Foundation
import SwiftData

@Model
final class Song {
    var uuid: UUID
    var fileURL: URL
    var artwork: Data?
    var title: String?
    var artist: String?
    var duration: TimeInterval?
    
    init(fileURL: URL, artwork: Data? = nil, title: String? = nil, artist: String? = nil, duration: TimeInterval? = nil) {
        self.uuid = UUID()
        self.fileURL = fileURL
        self.artwork = artwork
        self.title = title
        self.artist = artist
        self.duration = duration
    }
    
    func getURLString() -> String {
        return "\(fileURL)"
    }
    func print() -> UUID {
        return self.uuid
    }
}
