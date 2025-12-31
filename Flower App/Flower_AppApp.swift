//
//  Flower_AppApp.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData

@main
struct Flower_AppApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Flower.self,
            DailyCare.self,  // B-004: Add DailyCare model for saving answers and photos
            ChatMessage.self,  // Chat messages for follow-up conversations
            QuestionHistory.self,  // History of completed questions
            UserSettings.self,  // User settings including active flower slots
            FlowerActivationRequest.self,  // Activation/deactivation requests between partners
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
