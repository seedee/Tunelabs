//
//  MetadataExtractor.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import Foundation
import AVFoundation
import UIKit
import Combine

class MetadataExtractor {
    
    static func getArtwork(for url: URL) -> AnyPublisher<UIImage?, Never> {
        Future<UIImage?, Never> { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVAsset(url: url)
                let metadata = asset.metadata
                
                for item in metadata {
                    guard let key = item.commonKey?.rawValue,
                          key == AVMetadataKey.commonKeyArtwork.rawValue,
                          let data = item.dataValue,
                          let image = UIImage(data: data) else { continue }
                    
                    return promise(.success(image))
                }
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
}
