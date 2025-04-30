//
//  AudioEditorViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 30/04/2025.
//

import Foundation
import Combine

class AudioEditorViewModel: ObservableObject {
    @Published var pitch: Float = 0.0
    @Published var speed: Float = 1.0
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let audioEditor = AudioEditor()
    private var cancellables = Set<AnyCancellable>()
    
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
