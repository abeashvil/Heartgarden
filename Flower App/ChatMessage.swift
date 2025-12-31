//
//  ChatMessage.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import Foundation
import SwiftData

// Chat message model for follow-up conversations
@Model
final class ChatMessage {
    var id: UUID
    var careId: UUID  // Links to the DailyCare entry
    var userId: String?
    var messageText: String
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        careId: UUID,
        userId: String? = "user1",
        messageText: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.careId = careId
        self.userId = userId
        self.messageText = messageText
        self.createdAt = createdAt
    }
    
    // Computed property to get userId with default
    var effectiveUserId: String {
        return userId ?? "user1"
    }
}

