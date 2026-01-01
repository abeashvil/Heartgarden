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
    var user1PhoneNumber: String?  // Phone number for user1
    var user2PhoneNumber: String?  // Phone number for user2
    var user1Email: String?  // Email for user1
    var user2Email: String?  // Email for user2
    var reminderEnabled: Bool?  // Whether daily reminders are enabled
    var reminderHour: Int?  // Hour for daily reminder (0-23)
    var reminderMinute: Int?  // Minute for daily reminder (0-59)
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        activeFlowerSlots: Int? = 1,  // Default: start with 1 active slot
        user1ProfilePicture: Data? = nil,
        user2ProfilePicture: Data? = nil,
        user1PhoneNumber: String? = nil,
        user2PhoneNumber: String? = nil,
        user1Email: String? = nil,
        user2Email: String? = nil,
        reminderEnabled: Bool? = false,  // Default: reminders disabled
        reminderHour: Int? = 20,  // Default: 8:00 PM
        reminderMinute: Int? = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.activeFlowerSlots = activeFlowerSlots
        self.user1ProfilePicture = user1ProfilePicture
        self.user2ProfilePicture = user2ProfilePicture
        self.user1PhoneNumber = user1PhoneNumber
        self.user2PhoneNumber = user2PhoneNumber
        self.user1Email = user1Email
        self.user2Email = user2Email
        self.reminderEnabled = reminderEnabled
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var effectiveActiveFlowerSlots: Int {
        return activeFlowerSlots ?? 1
    }
    
    var effectiveReminderEnabled: Bool {
        return reminderEnabled ?? false
    }
    
    var effectiveReminderHour: Int {
        return reminderHour ?? 20
    }
    
    var effectiveReminderMinute: Int {
        return reminderMinute ?? 0
    }
    
    // Get profile picture for a specific user
    func profilePicture(for userId: String) -> Data? {
        return userId == "user1" ? user1ProfilePicture : user2ProfilePicture
    }
    
    // Get phone number for a specific user
    func phoneNumber(for userId: String) -> String? {
        return userId == "user1" ? user1PhoneNumber : user2PhoneNumber
    }
    
    // Get email for a specific user
    func email(for userId: String) -> String? {
        return userId == "user1" ? user1Email : user2Email
    }
    
    // Set profile picture for a specific user
    func setProfilePicture(_ data: Data?, for userId: String) {
        if userId == "user1" {
            user1ProfilePicture = data
        } else {
            user2ProfilePicture = data
        }
        updatedAt = Date()
    }
    
    // Set phone number for a specific user
    func setPhoneNumber(_ phoneNumber: String?, for userId: String) {
        if userId == "user1" {
            user1PhoneNumber = phoneNumber
        } else {
            user2PhoneNumber = phoneNumber
        }
        updatedAt = Date()
    }
    
    // Set email for a specific user
    func setEmail(_ email: String?, for userId: String) {
        if userId == "user1" {
            user1Email = email
        } else {
            user2Email = email
        }
        updatedAt = Date()
    }
}

