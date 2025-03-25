//
//  Item.swift
//  Tunelabs
//
//  Created by Daniil Lebedev on 25/03/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
