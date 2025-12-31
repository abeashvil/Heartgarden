//
//  UserSettings.swift
//  Flower App
//
//  Created for tracking user app settings
//

import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var activeFlowerSlots: Int?  // Number of active flower slots (starts at 1)
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        activeFlowerSlots: Int? = 1,  // Default: start with 1 active slot
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.activeFlowerSlots = activeFlowerSlots
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var effectiveActiveFlowerSlots: Int {
        return activeFlowerSlots ?? 1
    }
}

