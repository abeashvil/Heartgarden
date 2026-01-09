//
//  Flower.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Flower {
    var id: UUID
    var name: String
    var imageName: String
    var isCurrent: Bool  // Which active flower is currently being displayed
    var createdAt: Date
    
    // Active vs Owned distinction
    var isActive: Bool?  // Whether this flower is currently active (being cared for)
    var isOwned: Bool?   // Whether this flower type is owned (in the index)
    
    // Health system properties (optional for backward compatibility)
    var health: Double?  // Current health (0-100)
    var maxHealth: Double?  // Maximum health (default 100)
    var careLevel: Double?  // Care difficulty (1.0 = easy, 2.0 = medium, 3.0 = hard) - affects depletion rate
    var lastCareDate: Date?  // Last time both users completed care
    
    // Streak tracking (D-009)
    var streakCount: Int?  // Number of consecutive days both users completed care
    var lastStreakDate: Date?  // Last date that contributed to the streak
    
    // Unlock system (B-008: F-006)
    var unlockRequirement: Int?  // Streak requirement to unlock this flower (nil = already owned/unlocked)
    var unlockType: String?  // "streak" or "purchase" - how this flower can be unlocked
    
    // Question genre
    var questionGenre: String?  // Genre of questions for this flower (e.g., "romantic", "spicy", "informational")
    
    // Computed properties with defaults for backward compatibility
    var effectiveHealth: Double {
        return health ?? 100.0
    }
    
    var effectiveMaxHealth: Double {
        return maxHealth ?? 100.0
    }
    
    var effectiveCareLevel: Double {
        return careLevel ?? 1.0
    }
    
    var effectiveIsActive: Bool {
        return isActive ?? false
    }
    
    var effectiveIsOwned: Bool {
        return isOwned ?? false
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        imageName: String,
        isCurrent: Bool = false,
        createdAt: Date = Date(),
        isActive: Bool? = false,
        isOwned: Bool? = false,
        health: Double? = 100.0,
        maxHealth: Double? = 100.0,
        careLevel: Double? = 1.0,
        lastCareDate: Date? = nil,
        streakCount: Int? = 0,
        lastStreakDate: Date? = nil,
        unlockRequirement: Int? = nil,
        unlockType: String? = nil,
        questionGenre: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.isCurrent = isCurrent
        self.createdAt = createdAt
        self.isActive = isActive
        self.isOwned = isOwned
        self.health = health
        self.maxHealth = maxHealth
        self.careLevel = careLevel
        self.lastCareDate = lastCareDate
        self.streakCount = streakCount
        self.lastStreakDate = lastStreakDate
        self.unlockRequirement = unlockRequirement
        self.unlockType = unlockType
        self.questionGenre = questionGenre
    }
    
    // Computed property to get question genre with default
    var effectiveQuestionGenre: String {
        return questionGenre ?? QuestionGenre.relationship.rawValue
    }
    
    // Computed property with default for backward compatibility
    var effectiveStreakCount: Int {
        return streakCount ?? 0
    }
    
    // Computed property to get health percentage
    var healthPercentage: Double {
        let maxHealth = effectiveMaxHealth
        guard maxHealth > 0 else { return 0 }
        let percentage = effectiveHealth / maxHealth
        return min(Swift.max(percentage, 0), 1.0)
    }
}

