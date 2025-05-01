//
//  AudioEditorViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//

import Foundation
import Combine

extension AudioEditorViewModel {
    func processAudioAsync(url: URL) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            processAudio(url: url) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

class AudioEditorViewModel: ObservableObject {
    @Published var pitch: Float = 0.0 {
        didSet { updatePreviewEffects() }
    }
    @Published var speed: Float = 1.0 {
        didSet { updatePreviewEffects() }
    }
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    @Published var previewPlayer = AudioPreviewPlayer()
    
    private let audioEditor = AudioEditor()
    private var cancellables = Set<AnyCancellable>()
    
    func loadAudio(url: URL) {
        previewPlayer.loadAudio(url: url)
    }
        
    private func updatePreviewEffects() {
        previewPlayer.updateEffects(pitch: pitch, speed: speed)
    }
    
    func processAudio(url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        guard !isProcessing else { return }
        
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let processedURL = try await audioEditor.processAudio(
                    url: url,
                    pitch: pitch,
                    speed: speed
                )
                
                await MainActor.run {
                    self.isProcessing = false
                    completion(.success(processedURL))
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
        }
    }
    
    func resetParameters() {
        pitch = 0.0
        speed = 1.0
    }
}
