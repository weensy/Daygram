//
//  Item.swift
//  Daygram
//
//  Created by woonjin.kim on 2025/09/10.
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
