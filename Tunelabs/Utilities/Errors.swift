//
//  Errors.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 01/05/2025.
//

import Foundation
enum StorageError: Error, LocalizedError {
    case insufficientSpace
    
    var errorDescription: String? {
        switch self {
        case .insufficientSpace:
            return "Not enough storage space available"
        }
    }
}

enum ProcessingError: Error, LocalizedError {
    case cancelled
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Processing was cancelled"
        case .timeout:
            return "Processing took too long and was cancelled"
        }
    }
}
