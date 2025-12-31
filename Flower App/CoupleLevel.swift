//
//  CoupleLevel.swift
//  Flower App
//
//  Created for tracking couple level, experience, and available questions
//

import Foundation
import SwiftData

@Model
final class CoupleLevel {
    var id: UUID
    var level: Int  // Current level (starts at 1)
    var experience: Int  // Current experience points
    var totalExperience: Int  // Total experience earned (cumulative)
    var questionsAvailable: Int  // Number of questions available at current level
    var questionsUsed: Int  // Number of questions used today
    var guaranteedQuestionsPerUser: Int?  // Guaranteed minimum questions per user (default 2) - optional for migration
    var lastResetDate: Date  // Last date questions were reset
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        level: Int = 1,
        experience: Int = 0,
        totalExperience: Int = 0,
        questionsAvailable: Int = 4,  // Start with 4 questions per day (shared across all flowers)
        questionsUsed: Int = 0,
        guaranteedQuestionsPerUser: Int? = 2,  // Each user gets 2 guaranteed questions
        lastResetDate: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.level = level
        self.experience = experience
        self.totalExperience = totalExperience
        self.questionsAvailable = questionsAvailable
        self.questionsUsed = questionsUsed
        self.guaranteedQuestionsPerUser = guaranteedQuestionsPerUser
        self.lastResetDate = lastResetDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Calculate experience needed for next level
    var experienceNeededForNextLevel: Int {
        // Exponential growth: level * 100 + (level - 1) * 50
        return level * 100 + (level - 1) * 50
    }
    
    // Calculate progress to next level (0.0 to 1.0)
    var progressToNextLevel: Double {
        guard experienceNeededForNextLevel > 0 else { return 0.0 }
        return min(1.0, Double(experience) / Double(experienceNeededForNextLevel))
    }
    
    // Check if questions should be reset (new day)
    var shouldResetQuestions: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastReset = calendar.startOfDay(for: lastResetDate)
        return today > lastReset
    }
    
    // Reset questions for new day
    func resetDailyQuestions() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        questionsUsed = 0
        lastResetDate = today
        updatedAt = Date()
    }
    
    // Safe accessor for guaranteedQuestionsPerUser with default
    var safeGuaranteedQuestionsPerUser: Int {
        return guaranteedQuestionsPerUser ?? 2
    }
    
    // Calculate shared questions available (total - guaranteed per user * 2)
    var sharedQuestionsAvailable: Int {
        let guaranteedTotal = safeGuaranteedQuestionsPerUser * 2
        return max(0, questionsAvailable - guaranteedTotal)
    }
    
    // Add experience and check for level up
    func addExperience(_ amount: Int) -> Bool {
        experience += amount
        totalExperience += amount
        updatedAt = Date()
        
        // Check for level up
        if experience >= experienceNeededForNextLevel {
            return levelUp()
        }
        return false
    }
    
    // Level up and return true if leveled up
    func levelUp() -> Bool {
        let didLevelUp = experience >= experienceNeededForNextLevel
        
        if didLevelUp {
            experience -= experienceNeededForNextLevel
            level += 1
            // Increase questions available by 1 every 2 levels
            if level % 2 == 0 {
                questionsAvailable += 1
            }
            updatedAt = Date()
        }
        
        return didLevelUp
    }
    
    // Get rewards for current level
    func getLevelRewards() -> [String] {
        var rewards: [String] = []
        
        // Every level: unlock new questions
        rewards.append("New questions unlocked")
        
        // Every 3 levels: unlock a new flower
        if level % 3 == 0 {
            rewards.append("New flower unlocked")
        }
        
        // Every 5 levels: bonus questions
        if level % 5 == 0 {
            rewards.append("Bonus questions")
        }
        
        return rewards
    }
}

