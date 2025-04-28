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
    var fileURL: URL
    var artworkData: Data?
    var title: String?
    var artist: String?
    var duration: TimeInterval?
    
    init(fileURL: URL, artworkData: Data? = nil, title: String? = nil, artist: String? = nil, duration: TimeInterval? = nil) {
        self.fileURL = fileURL
        self.artworkData = artworkData
        self.title = title
        self.artist = artist
        self.duration = duration
    }
}
