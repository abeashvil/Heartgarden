//
//  DailyCare.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import Foundation
import SwiftData

// Daily Care Model - D-006 (answer text) and D-007 (photo data)
@Model
final class DailyCare {
    var id: UUID
    var flowerId: UUID
    var userId: String?  // User identifier (optional for backward compatibility)
    var date: Date
    var answerText: String  // D-006: User's answer text
    var photoData: Data?    // D-007: User's photo for the day
    var isCompleted: Bool
    var createdAt: Date
    var questionText: String?  // The question that was answered
    var isArchived: Bool?  // Whether this question has been moved to history (optional for backward compatibility)
    
    // Computed property with default for backward compatibility
    var effectiveIsArchived: Bool {
        return isArchived ?? false
    }
    
    init(
        id: UUID = UUID(),
        flowerId: UUID,
        userId: String? = "user1",  // Default to user1, but optional for existing data
        date: Date = Date(),
        answerText: String,
        photoData: Data? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        questionText: String? = nil,
        isArchived: Bool? = false
    ) {
        self.id = id
        self.flowerId = flowerId
        self.userId = userId
        self.date = date
        self.answerText = answerText
        self.photoData = photoData
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.questionText = questionText
        self.isArchived = isArchived
    }
    
    // Computed property to get userId with default
    var effectiveUserId: String {
        return userId ?? "user1"
    }
}

