//
//  Item.swift
//  WoodFishApp
//
//  Created by 张栩萌 on 2025/3/7.
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
