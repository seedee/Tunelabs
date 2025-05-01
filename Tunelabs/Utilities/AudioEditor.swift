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
    case formatError
    case exportError
    
    var errorDescription: String? {
        switch self {
        case .fileAccessError:
            return "Could not access the audio file"
        case .processingError(let message):
            return "Processing error: \(message)"
        case .formatError:
            return "Unsupported audio format or file type"
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
            
            // Validate input parameters
            guard abs(pitch) <= 12 else {
                throw AudioEditingError.processingError("Pitch must be between -12 and 12 semitones")
            }
            guard speed >= 0.5 && speed <= 2.0 else {
                throw AudioEditingError.processingError("Speed must be between 0.5x and 2.0x")
            }
            
            // Load audio file
            guard let audioFile = try? AVAudioFile(forReading: url) else {
                throw AudioEditingError.fileAccessError
            }
            
            // Prepare buffer
            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                throw AudioEditingError.formatError
            }
            
            try audioFile.read(into: buffer)
            
            // Prepare output file
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            // Configure audio processing
            let mainMixerNode = engine.mainMixerNode
            let outputNode = engine.outputNode
            let outputFormat = outputNode.outputFormat(forBus: 0)
            
            // Reset and configure engine
            engine.stop()
            engine.disconnectNodeInput(mainMixerNode)
            
            // Apply pitch and speed effects
            pitchControl.pitch = pitch
            pitchControl.rate = speed
            
            // Reconnect nodes
            engine.connect(player, to: pitchControl, format: nil)
            engine.connect(pitchControl, to: mainMixerNode, format: nil)
            engine.connect(mainMixerNode, to: outputNode, format: outputFormat)
            
            // Prepare for rendering
            try engine.enableManualRenderingMode(.offline,
                                                 format: outputFormat,
                                                 maximumFrameCount: 4096)
            
            // Create output file
            let outputFile = try AVAudioFile(
                forWriting: outputURL,
                settings: outputFormat.settings,
                commonFormat: .pcmFormatFloat32,
                interleaved: false
            )
            
            // Start engine and player
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            player.play()
            
            // Prepare output buffer
            let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: 4096
            )!
            
            // Render audio
            while try engine.renderOffline(AVAudioFrameCount(buffer.frameLength), to: outputBuffer) == .success {
                try outputFile.write(from: outputBuffer)
            }
            
            // Cleanup
            cleanup()
            
            return outputURL
            
        } catch let error as AudioEditingError {
            // Rethrow known audio editing errors
            throw error
        } catch {
            // Log unexpected errors
            print("Unexpected audio processing error: \(error)")
            throw AudioEditingError.processingError(error.localizedDescription)
        }
    }
    
    private func cleanup() {
        do {
            if engine.isRunning {
                player.stop()
                engine.stop()
            }
        } catch {
            print("Error during audio engine cleanup: \(error)")
        }
    }
    
    deinit {
        cleanup()
    }
}
