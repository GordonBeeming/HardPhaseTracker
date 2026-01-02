//
//  Item.swift
//  HardPhaseTracker
//
//  Created by Gordon Beeming on 2/1/2026.
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
