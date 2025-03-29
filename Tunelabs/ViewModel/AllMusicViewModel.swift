//
//  AllMusicViewModel.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 29/03/2025.
//

import SwiftUI
import Combine

class AllMusicViewModel: ObservableObject {
    @Published private(set) var coverArtCache: [URL: UIImage] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    func loadCoverArt(for url: URL) {
        guard !coverArtCache.keys.contains(url) else { return }
        
        MetadataExtractor.getCoverArt(for: url)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.coverArtCache[url] = image
            }
            .store(in: &cancellables)
    }
}
