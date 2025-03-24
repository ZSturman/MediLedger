//
//  Item.swift
//  MedTracker
//
//  Created by Zachary Sturman on 3/24/25.
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
