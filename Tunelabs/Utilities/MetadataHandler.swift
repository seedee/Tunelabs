//
//  MetadataHandler.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 28/04/2025.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct SongMetadata {
    let title: String?
    let artist: String?
    let duration: TimeInterval?
    let artwork: Data?
}

enum MetadataError: Error, LocalizedError {
    case unsupportedFileType(String)
    case exporterCreationFailed
    case unknownExportError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .exporterCreationFailed:
            return "Could not create exporter for this file type"
        case .unknownExportError:
            return "Export failed for unknown reason"
        }
    }
}

class MetadataHandler {
    static func readMetadata(from url: URL) async -> SongMetadata {
        let asset = AVAsset(url: url)
        
        do {
            let duration = try await asset.load(.duration)
            let metadata = try await asset.load(.commonMetadata) // Use commonMetadata
            
            var title: String?
            var artist: String?
            var artwork: Data?
            
            for item in metadata {
                guard let commonKey = item.commonKey else { continue }
                switch commonKey {
                case AVMetadataKey.commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case AVMetadataKey.commonKeyArtist:
                    artist = try? await item.load(.stringValue)
                case AVMetadataKey.commonKeyArtwork:
                    artwork = try? await item.load(.dataValue)
                default:
                    break
                }
            }
            
            return SongMetadata(
                title: title ?? url.deletingPathExtension().lastPathComponent,
                artist: artist,
                duration: CMTimeGetSeconds(duration),
                artwork: artwork
            )
        } catch {
            return SongMetadata(
                title: url.deletingPathExtension().lastPathComponent,
                artist: nil,
                duration: nil,
                artwork: nil
            )
        }
    }

    static func writeMetadata(to url: URL, title: String?, artist: String?, artwork: Data?) async throws {
        let asset = AVAsset(url: url)
        let composition = AVMutableComposition()
        
        try await composition.insertTimeRange(
            CMTimeRange(start: .zero, duration: try await asset.load(.duration)),
            of: asset,
            at: .zero
        )
        
        var metadataItems = [AVMetadataItem]()
        
        // Title
        if let title = title {
            let item = AVMutableMetadataItem()
            item.key = AVMetadataKey.commonKeyTitle as NSString
            item.keySpace = AVMetadataKeySpace.common
            item.value = title as NSString
            metadataItems.append(item)
        }
        
        // Artist
        if let artist = artist {
            let item = AVMutableMetadataItem()
            item.key = AVMetadataKey.commonKeyArtist as NSString
            item.keySpace = AVMetadataKeySpace.common
            item.value = artist as NSString
            metadataItems.append(item)
        }
        
        // Artwork
        if let artwork = artwork {
            let item = AVMutableMetadataItem()
            item.key = AVMetadataKey.commonKeyArtwork as NSString
            item.keySpace = AVMetadataKeySpace.common
            item.value = artwork as NSData
            metadataItems.append(item)
        }
        
        // File Type Handling with preset selection
        let (outputFileType, presetName, fileExtension) = try determineExportSettings(for: url.pathExtension)
                
        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: presetName
        ) else {
            throw MetadataError.exporterCreationFailed
        }
        
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(fileExtension)
        
        exporter.outputURL = outputURL
        exporter.outputFileType = outputFileType
        exporter.metadata = metadataItems
        
        await exporter.export()
        
        guard exporter.status == .completed else {
            let errorMessage = exporter.error?.localizedDescription ?? "No error details"
            throw NSError(
                domain: "MetadataExport",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Export failed: \(errorMessage)"]
            )
        }
        
        // Get the URL for the result
        let updatedURL = try replaceOriginalFile(at: url, with: outputURL, newExtension: fileExtension)
        
        // If the URL has changed, we need to update references in the app
        // This will be handled by the calling code with the returned URL
        if updatedURL != url {
            NotificationCenter.default.post(
                name: Notification.Name("MetadataFileURLChanged"),
                object: nil,
                userInfo: ["oldURL": url, "newURL": updatedURL]
            )
        }
    }
    
    private static func determineExportSettings(for fileExtension: String) throws -> (AVFileType, String, String) {
        let lowerExtension = fileExtension.lowercased()
        
        switch lowerExtension {
        case "mp3":
            // Convert MP3 to M4A with correct extension
            return (.m4a, AVAssetExportPresetAppleM4A, "m4a")
        case "m4a":
            return (.m4a, AVAssetExportPresetAppleM4A, "m4a")
        case "wav":
            return (.wav, AVAssetExportPresetPassthrough, "wav")
        case "aif", "aiff":
            return (.aiff, AVAssetExportPresetPassthrough, "aiff")
        default:
            guard let type = UTType(filenameExtension: lowerExtension),
                  let mimeType = type.preferredMIMEType else {
                throw MetadataError.unsupportedFileType(lowerExtension)
            }
            
            switch mimeType {
            case "audio/mpeg", "audio/mp4":
                return (.m4a, AVAssetExportPresetAppleM4A, "m4a")
            case "audio/x-wav":
                return (.wav, AVAssetExportPresetPassthrough, "wav")
            default:
                throw MetadataError.unsupportedFileType(lowerExtension)
            }
        }
    }
    
    private static func replaceOriginalFile(at originalURL: URL, with newURL: URL, newExtension: String) throws -> URL {
        let fileManager = FileManager.default
        let originalPath = originalURL.path
        
        // 1. Calculate new path if extension changed
        let newFileName = originalURL.deletingPathExtension().lastPathComponent
        let targetURL = originalURL.deletingLastPathComponent()
            .appendingPathComponent(newFileName)
            .appendingPathExtension(newExtension)
        
        // 2. Remove original file if it exists
        if fileManager.fileExists(atPath: originalPath) {
            try fileManager.removeItem(at: originalURL)
        }
        
        // 3. If target exists (but is different from original), remove it
        if targetURL != originalURL && fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        // 4. Move exported file
        try fileManager.moveItem(at: newURL, to: targetURL)
        
        // 5. Return the final URL - could be different if extension changed
        return targetURL
    }
}
