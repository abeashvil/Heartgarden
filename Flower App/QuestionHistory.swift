//
//  QuestionHistory.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/30/25.
//

import Foundation
import SwiftData

// Model to track completed questions that have been answered by both users
@Model
final class QuestionHistory {
    var id: UUID
    var flowerId: UUID
    var questionText: String
    var dateCompleted: Date  // When both users completed the question
    var user1CareId: UUID?  // Reference to user1's DailyCare entry
    var user2CareId: UUID?  // Reference to user2's DailyCare entry
    var createdAt: Date
    var lastViewedByUser1: Date?  // When user1 last viewed this chat
    var lastViewedByUser2: Date?  // When user2 last viewed this chat
    var isSaved: Bool?  // Whether this chat is saved (optional for backward compatibility)
    
    init(
        id: UUID = UUID(),
        flowerId: UUID,
        questionText: String,
        dateCompleted: Date = Date(),
        user1CareId: UUID? = nil,
        user2CareId: UUID? = nil,
        createdAt: Date = Date(),
        lastViewedByUser1: Date? = nil,
        lastViewedByUser2: Date? = nil,
        isSaved: Bool? = false
    ) {
        self.id = id
        self.flowerId = flowerId
        self.questionText = questionText
        self.dateCompleted = dateCompleted
        self.user1CareId = user1CareId
        self.user2CareId = user2CareId
        self.createdAt = createdAt
        self.lastViewedByUser1 = lastViewedByUser1
        self.lastViewedByUser2 = lastViewedByUser2
        self.isSaved = isSaved
    }
    
    // Computed property with default for backward compatibility
    var effectiveIsSaved: Bool {
        return isSaved ?? false
    }
    
    // Get last viewed date for a specific user
    func lastViewedDate(for userId: String) -> Date? {
        return userId == "user1" ? lastViewedByUser1 : lastViewedByUser2
    }
    
    // Mark as viewed by a user
    func markAsViewed(by userId: String) {
        if userId == "user1" {
            lastViewedByUser1 = Date()
        } else {
            lastViewedByUser2 = Date()
        }
    }
}

