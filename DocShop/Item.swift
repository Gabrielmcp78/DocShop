//
//  Item.swift
//  DocShop
//
//  Created by Gabriel McPherson on 6/28/25.
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
