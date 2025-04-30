//
//  AudioEditor.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//

import Foundation
import AVFoundation

enum AudioEditingError: Error, LocalizedError {
    case fileAccessError
    case processingError(String)
    case exportError
    
    var errorDescription: String? {
        switch self {
        case .fileAccessError:
            return "Could not access the audio file"
        case .processingError(let message):
            return "Processing error: \(message)"
        case .exportError:
            return "Could not export the edited audio"
        }
    }
}

class AudioEditor {
    private var engine: AVAudioEngine
    private var player: AVAudioPlayerNode
    private var pitchControl: AVAudioUnitTimePitch
    
    init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        pitchControl = AVAudioUnitTimePitch()
        
        engine.attach(player)
        engine.attach(pitchControl)
        
        engine.connect(player, to: pitchControl, format: nil)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
    }
    
    func processAudio(url: URL, pitch: Float, speed: Float) async throws -> URL {
        // Stop any ongoing processing
        cleanup()
        
        do {
            try engine.start()
            
            // Load and configure audio
            let file = try AVAudioFile(forReading: url)
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: buffer!)
            
            // Apply effects
            pitchControl.pitch = pitch
            pitchControl.rate = speed
            
            // Create temporary output file
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            // Configure and start recording
            let format = pitchControl.outputFormat(forBus: 0)
            
            engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
            try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 4096)
            
            // Create output file
            let outputFile = try AVAudioFile(
                forWriting: outputURL,
                settings: format.settings,
                commonFormat: format.commonFormat,
                interleaved: false
            )
            
            // Play audio through effects chain
            player.scheduleBuffer(buffer!, at: nil, options: .interrupts, completionHandler: nil)
            player.play()
            
            // Render and write to file
            let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: 4096
            )!
            
            while engine.manualRenderingBlock(
                timeRange: AVAudioTimeRange(start: .zero, duration: AVAudioTime.hostTimeForSeconds(1.0/120.0)),
                to: outputBuffer
            ) == .success {
                try outputFile.write(from: outputBuffer)
            }
            
            cleanup()
            return outputURL
            
        } catch {
            cleanup()
            throw AudioEditingError.processingError(error.localizedDescription)
        }
    }
    
    private func cleanup() {
        if engine.isRunning {
            player.stop()
            engine.stop()
        }
    }
    
    deinit {
        cleanup()
    }
}
