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
    var user1ProfilePicture: Data?  // Profile picture for user1
    var user2ProfilePicture: Data?  // Profile picture for user2
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        activeFlowerSlots: Int? = 1,  // Default: start with 1 active slot
        user1ProfilePicture: Data? = nil,
        user2ProfilePicture: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.activeFlowerSlots = activeFlowerSlots
        self.user1ProfilePicture = user1ProfilePicture
        self.user2ProfilePicture = user2ProfilePicture
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var effectiveActiveFlowerSlots: Int {
        return activeFlowerSlots ?? 1
    }
    
    // Get profile picture for a specific user
    func profilePicture(for userId: String) -> Data? {
        return userId == "user1" ? user1ProfilePicture : user2ProfilePicture
    }
}

