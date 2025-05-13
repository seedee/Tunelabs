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
    // Using a new audio engine for each processing task to avoid state contamination
    private var engine: AVAudioEngine
    private var player: AVAudioPlayerNode
    private var pitchControl: AVAudioUnitTimePitch
    
    init() {
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        pitchControl = AVAudioUnitTimePitch()
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(player)
        engine.attach(pitchControl)
        
        engine.connect(player, to: pitchControl, format: nil)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: nil)
    }
    
    func processAudio(url: URL, pitch: Float, speed: Float) async throws -> URL {
        // Reset everything for a clean slate
        resetAudioEngine()
        
        do {
            // Validate input parameters
            guard abs(pitch) <= 12 else {
                throw AudioEditingError.processingError("Pitch must be between -12 and 12 semitones")
            }
            guard speed >= 0.5 && speed <= 2.0 else {
                throw AudioEditingError.processingError("Speed must be between 0.5x and 2.0x")
            }
            
            // Load audio file
            let audioFile: AVAudioFile
            do {
                audioFile = try AVAudioFile(forReading: url)
            } catch {
                print("Error opening audio file: \(error)")
                throw AudioEditingError.fileAccessError
            }
            
            // Get format information for better compatibility
            let inputFormat = audioFile.processingFormat
            print("Processing audio with format: \(inputFormat.sampleRate) Hz, \(inputFormat.channelCount) channels")
            
            // Prepare buffer with appropriate capacity
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: AVAudioFrameCount(audioFile.length)
            ) else {
                throw AudioEditingError.formatError
            }
            
            // Read file into buffer
            do {
                try audioFile.read(into: buffer)
            } catch {
                print("Error reading audio data: \(error)")
                throw AudioEditingError.fileAccessError
            }
            
            // Create unique output filename
            var outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(url.pathExtension)
            
            // Configure effects
            pitchControl.pitch = pitch * 100 // Semitones to cents
            pitchControl.rate = speed
            
            // Ensure engine is stopped before configuration
            if engine.isRunning {
                engine.stop()
            }
            
            // Connect with explicit format
            engine.connect(player, to: pitchControl, format: inputFormat)
            engine.connect(pitchControl, to: engine.mainMixerNode, format: inputFormat)
            
            // Enable manual rendering mode with appropriate buffer size
            do {
                // Use a smaller frame count (1024) for more stable processing
                try engine.enableManualRenderingMode(
                    .offline,
                    format: inputFormat,
                    maximumFrameCount: 1024
                )
            } catch {
                print("Failed to enable manual rendering: \(error)")
                throw AudioEditingError.processingError("Could not configure audio engine: \(error.localizedDescription)")
            }
            
            // Create output file with explicit settings instead of reusing input format settings
            let outputFile: AVAudioFile
            do {
                // Define explicit output settings to ensure compatibility
                var outputSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: inputFormat.sampleRate,
                    AVNumberOfChannelsKey: inputFormat.channelCount,
                    AVLinearPCMBitDepthKey: 32,
                    AVLinearPCMIsFloatKey: true,
                    AVLinearPCMIsNonInterleaved: true
                ]
                
                // For MP3 files, convert to a more compatible format
                if url.pathExtension.lowercased() == "mp3" {
                    outputSettings = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: inputFormat.sampleRate,
                        AVNumberOfChannelsKey: inputFormat.channelCount,
                        AVEncoderBitRateKey: 256000
                    ]
                    
                    // Change output extension to m4a for MPEG4 AAC
                    outputURL = outputURL.deletingPathExtension().appendingPathExtension("m4a")
                }
                
                outputFile = try AVAudioFile(
                    forWriting: outputURL,
                    settings: outputSettings,
                    commonFormat: .pcmFormatFloat32,
                    interleaved: false
                )
            } catch {
                print("Failed to create output file: \(error)")
                print("Output URL: \(outputURL)")
                print("Format settings attempted: \(inputFormat.settings)")
                throw AudioEditingError.exportError
            }
            
            // Start engine
            do {
                try engine.start()
            } catch {
                print("Failed to start audio engine: \(error)")
                throw AudioEditingError.processingError("Could not start audio engine: \(error.localizedDescription)")
            }
            
            // Schedule buffer playback
            player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
            player.play()
            
            // Create render buffer with appropriate size
            guard let renderBuffer = AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity: 1024
            ) else {
                throw AudioEditingError.formatError
            }
            
            // Process audio in smaller chunks for better stability
            var renderedFrames: AVAudioFrameCount = 0
            let totalFrames = AVAudioFrameCount(buffer.frameLength)
            
            print("Starting rendering: \(totalFrames) total frames")
            
            // Process in smaller chunks (1024 frames) with more graceful error handling
            while renderedFrames < totalFrames {
                let framesToRender = min(1024, totalFrames - renderedFrames)
                
                // Clear the render buffer for this iteration
                for i in 0..<renderBuffer.frameLength {
                    for channel in 0..<renderBuffer.format.channelCount {
                        renderBuffer.floatChannelData?[Int(channel)][Int(i)] = 0.0
                    }
                }
                
                // Render the next chunk
                let renderStatus = try engine.renderOffline(framesToRender, to: renderBuffer)
                
                // Handle render status
                switch renderStatus {
                case .success:
                    // Write successful render to output file
                    do {
                        try outputFile.write(from: renderBuffer)
                        renderedFrames += framesToRender
                        
                        // Log progress periodically
                        if renderedFrames % 44100 == 0 { // Log about once per second of audio
                            print("Rendered \(renderedFrames)/\(totalFrames) frames (\(Int(Double(renderedFrames) / Double(totalFrames) * 100))%)")
                        }
                    } catch {
                        print("Failed to write to output file: \(error)")
                        throw AudioEditingError.exportError
                    }
                    
                case .insufficientDataFromInputNode:
                    // This can happen when we've reached the end of the audio
                    print("Reached end of input buffer at \(renderedFrames)/\(totalFrames) frames")
                    break
                    
                case .cannotDoInCurrentContext:
                    throw AudioEditingError.processingError("Cannot render in current context")
                    
                case .error:
                    throw AudioEditingError.processingError("Engine rendering error")
                    
                @unknown default:
                    throw AudioEditingError.processingError("Unknown rendering error")
                }
                
                // Break if we've reached the end for any reason
                if renderStatus != .success {
                    break
                }
            }
            
            print("Rendering complete: \(renderedFrames)/\(totalFrames) frames processed")
            
            // Stop engine and cleanup
            cleanup()
            
            return outputURL
            
        } catch let error as AudioEditingError {
            // Clean up on error
            cleanup()
            throw error
        } catch {
            // Clean up on unexpected error
            cleanup()
            print("Unexpected audio processing error: \(error)")
            throw AudioEditingError.processingError(error.localizedDescription)
        }
    }
    
    private func resetAudioEngine() {
        cleanup()
        
        // Create fresh engine components
        engine = AVAudioEngine()
        player = AVAudioPlayerNode()
        pitchControl = AVAudioUnitTimePitch()
        
        // Set up clean configuration
        setupAudioEngine()
    }
    
    private func cleanup() {
        // Stop player and engine if running
        if player.isPlaying {
            player.stop()
        }
        
        if engine.isRunning {
            engine.stop()
        }
    }
    
    deinit {
        cleanup()
    }
}
