//
//  Item.swift
//  run-jin
//
//  Created by Koichi Takahashi on 2026/04/05.
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
