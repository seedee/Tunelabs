//
//  MetadataExtractor.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import SwiftUI
import AVFoundation

struct SongMetadata {
    let title: String?
    let artist: String?
    let duration: TimeInterval?
    let artworkData: Data?
}

class MetadataExtractor {
    static func extractMetadata(for url: URL, completion: @escaping (SongMetadata) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            var title: String?
            var artist: String?
            var duration: TimeInterval?
            var artworkData: Data?
            
            // Extract duration
            duration = CMTimeGetSeconds(asset.duration)
            
            // Extract other metadata
            for item in asset.metadata {
                guard let commonKey = item.commonKey?.rawValue else { continue }
                
                switch commonKey {
                case AVMetadataKey.commonKeyTitle.rawValue:
                    title = item.stringValue
                case AVMetadataKey.commonKeyArtist.rawValue:
                    artist = item.stringValue
                case AVMetadataKey.commonKeyArtwork.rawValue:
                    artworkData = item.dataValue
                default:
                    break
                }
            }
            
            DispatchQueue.main.async {
                completion(SongMetadata(
                    title: title,
                    artist: artist,
                    duration: duration,
                    artworkData: artworkData
                ))
            }
        }
    }
}
