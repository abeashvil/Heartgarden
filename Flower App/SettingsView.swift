//
//  SettingsView.swift
//  Flower App
//
//  Created for B-009: Add reminders and polish the app
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    let selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    
    @State private var reminderEnabled: Bool = false
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    private var transparentBoxBackground: some View {
        ZStack {
            selectedTheme.backgroundColor
            if selectedTheme == .darkMode {
                Color.white.opacity(0.1)
            } else {
                Color.white.opacity(0.4)
            }
        }
    }
    
    private var settings: UserSettings {
        if let existing = userSettings.first {
            return existing
        } else {
            let newSettings = UserSettings()
            modelContext.insert(newSettings)
            do {
                try modelContext.save()
            } catch {
                print("Error creating UserSettings: \(error)")
            }
            return newSettings
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Reminder Settings Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Daily Reminders")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(primaryTextColor)
                            
                            // Enable/Disable Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Enable Daily Reminders")
                                        .font(.headline)
                                        .foregroundColor(primaryTextColor)
                                    Text("Get notified to care for your flowers")
                                        .font(.caption)
                                        .foregroundColor(primaryTextColor.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $reminderEnabled)
                                    .onChange(of: reminderEnabled) { oldValue, newValue in
                                        updateReminderSettings()
                                    }
                            }
                            .padding()
                            .background(transparentBoxBackground)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .foregroundColor(primaryTextColor)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }
    
    private func loadSettings() {
        let settings = self.settings
        reminderEnabled = settings.effectiveReminderEnabled
    }
    
    private func updateReminderSettings() {
        let settings = self.settings
        settings.reminderEnabled = reminderEnabled
        settings.updatedAt = Date()
        
        do {
            try modelContext.save()
            
            // Note: Notification scheduling with specific times will be handled
            // by the app's notification system based on programmed scenarios
            if reminderEnabled {
                // For now, use a default time (8 PM) - this will be replaced
                // with scenario-based scheduling in the future
                NotificationManager.shared.scheduleDailyReminder(
                    at: 20,
                    minute: 0,
                    isEnabled: true
                )
            } else {
                NotificationManager.shared.cancelAllReminders()
            }
        } catch {
            print("Error updating reminder settings: \(error)")
        }
    }
}

