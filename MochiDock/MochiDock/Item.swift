//
//  Item.swift
//  MochiDock
//
//  Created by Scott on 2026/7/18.
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
