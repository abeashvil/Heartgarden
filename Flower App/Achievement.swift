//
//  Achievement.swift
//  Flower App
//
//  Created for tracking couple achievements and milestones
//

import Foundation
import SwiftData

@Model
final class Achievement {
    var id: UUID
    var achievementId: String  // Unique identifier for the achievement
    var title: String
    var achievementDescription: String  // Renamed from 'description' to avoid conflict with @Model macro
    var category: String  // "level", "streak", "flowers", "questions"
    var requirement: Int  // Requirement value (e.g., level 5, streak 10)
    var currentProgress: Int  // Current progress toward achievement
    var isUnlocked: Bool
    var unlockedAt: Date?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        achievementId: String,
        title: String,
        achievementDescription: String,
        category: String,
        requirement: Int,
        currentProgress: Int = 0,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.achievementId = achievementId
        self.title = title
        self.achievementDescription = achievementDescription
        self.category = category
        self.requirement = requirement
        self.currentProgress = currentProgress
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.createdAt = createdAt
    }
    
    // Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard requirement > 0 else { return 0.0 }
        return min(1.0, Double(currentProgress) / Double(requirement))
    }
    
    // Update progress and check if unlocked
    func updateProgress(_ newProgress: Int) -> Bool {
        currentProgress = min(newProgress, requirement)
        
        if !isUnlocked && currentProgress >= requirement {
            isUnlocked = true
            unlockedAt = Date()
            return true  // Just unlocked
        }
        
        return false
    }
}

