//
//  NotificationManager.swift
//  Flower App
//
//  Created for B-009: Add reminders and polish the app
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Request notification permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // Check notification authorization status
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Schedule daily reminder
    func scheduleDailyReminder(at hour: Int, minute: Int, isEnabled: Bool) {
        // Remove existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard isEnabled else {
            print("Reminders are disabled")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Care for Your Flower 🌸"
        content.body = "Don't forget to answer today's question and send a photo to your partner!"
        content.sound = .default
        content.badge = 1
        
        // Create date components for the reminder time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // Create trigger (daily at specified time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let identifier = "dailyFlowerReminder"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
    
    // Cancel all reminders
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All reminders cancelled")
    }
    
    // Update badge count (optional - can be used to show unread items)
    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}

