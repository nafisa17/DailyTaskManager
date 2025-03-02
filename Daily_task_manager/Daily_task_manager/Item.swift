//
//  Item.swift
//  Daily_task_manager
//
//  Created by Nafisa Anjum on 02.03.25.
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
