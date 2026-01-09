//
//  FlowerViewModel.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

class FlowerViewModel: ObservableObject {
    @Published var currentFlower: Flower?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var partnerStatus: PartnerStatus = .waiting
    @Published var streakCount: Int = 0
    
    var modelContext: ModelContext?
    var currentUserId: String = "user1"  // Current user ID for partner status checking
    
    enum PartnerStatus {
        case completed
        case waiting
        case notConnected
    }
    
    // Initialize with SwiftData context
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    // Load current flower from SwiftData or create default (F-001)
    @MainActor
    func loadCurrentFlower() {
        isLoading = true
        errorMessage = nil
        
        // Try to load from SwiftData if context is available
        if let context = modelContext {
            do {
                // First, migrate existing flowers to have isActive and isOwned
                let allFlowersDescriptor = FetchDescriptor<Flower>()
                let allFlowers = try context.fetch(allFlowersDescriptor)
                for flower in allFlowers {
                    // Migrate: if isActive is nil, set based on isCurrent
                    if flower.isActive == nil {
                        flower.isActive = flower.isCurrent
                        flower.isOwned = true  // Existing flowers are owned
                        try context.save()
                    }
                }
                
                // Initialize default flowers if needed
                initializeDefaultFlowers(context: context)
                
                // Update UserSettings to 3 slots if needed
                let settingsDescriptor = FetchDescriptor<UserSettings>()
                if let settings = try? context.fetch(settingsDescriptor).first {
                    if settings.activeFlowerSlots == nil || settings.effectiveActiveFlowerSlots < 3 {
                        settings.activeFlowerSlots = 3
                        try context.save()
                    }
                } else {
                    // Create settings with 3 slots
                    let newSettings = UserSettings(activeFlowerSlots: 3)
                    context.insert(newSettings)
                    try context.save()
                }
                
                // Load current flower (prefer isCurrent, but fallback to first active)
                let currentDescriptor = FetchDescriptor<Flower>(
                    predicate: #Predicate<Flower> { $0.isCurrent == true },
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                var flowers = try context.fetch(currentDescriptor)
                
                // If no current flower, try to find first active flower
                if flowers.isEmpty {
                    let activeDescriptor = FetchDescriptor<Flower>(
                        predicate: #Predicate<Flower> { $0.isActive == true },
                        sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                    )
                    flowers = try context.fetch(activeDescriptor)
                    // Set first active flower as current
                    if let firstActive = flowers.first {
                        firstActive.isCurrent = true
                        try context.save()
                    }
                }
                
                if let flower = flowers.first {
                    // Found current flower in database
                    self.currentFlower = flower
                    // Migrate health properties if needed (for existing flowers)
                    if flower.health == nil {
                        flower.health = 100.0
                        flower.maxHealth = 100.0
                        flower.careLevel = 1.0
                        try context.save()
                    }
                    // Migrate streak properties if needed
                    if flower.streakCount == nil {
                        flower.streakCount = 0
                        try context.save()
                    }
                    // Update health based on time since last care
                    self.updateFlowerHealth(flower: flower)
                    // Calculate and update streak count
                    self.calculateStreak(flower: flower)
                    // Update partner status after loading flower
                    self.updatePartnerStatus()
                    self.isLoading = false
                    return
                } else {
                    // No current flower found, create a default one
                    // First, ensure UserSettings exists with 3 active slots
                    let settingsDescriptor = FetchDescriptor<UserSettings>()
                    let existingSettings = try? context.fetch(settingsDescriptor)
                    let settings = existingSettings?.first ?? UserSettings(activeFlowerSlots: 3)
                    if existingSettings?.isEmpty ?? true {
                        context.insert(settings)
                    } else {
                        // Update existing settings to 3 slots if it's still 1
                        if settings.activeFlowerSlots == nil || settings.effectiveActiveFlowerSlots < 3 {
                            settings.activeFlowerSlots = 3
                        }
                    }
                    
                    // Initialize default flowers if they don't exist
                    initializeDefaultFlowers(context: context)
                    
                    // Create default flower as both owned and active
                    let defaultFlower = Flower(
                        name: "Daily Flower",
                        imageName: "flower_red_bloomed",
                        isCurrent: true,
                        isActive: true,
                        isOwned: true,
                        health: 100.0,
                        maxHealth: 100.0,
                        careLevel: 1.0,
                        streakCount: 0,
                        questionGenre: QuestionGenre.relationship.rawValue
                    )
                    // Ensure health properties are set
                    if defaultFlower.health == nil {
                        defaultFlower.health = 100.0
                        defaultFlower.maxHealth = 100.0
                        defaultFlower.careLevel = 1.0
                    }
                    // Ensure streak properties are set
                    if defaultFlower.streakCount == nil {
                        defaultFlower.streakCount = 0
                    }
                    context.insert(defaultFlower)
                    try context.save()
                    self.currentFlower = defaultFlower
                    // Calculate initial streak
                    self.calculateStreak(flower: defaultFlower)
                    // Update partner status after creating flower
                    self.updatePartnerStatus()
                    self.isLoading = false
                    return
                }
            } catch {
                // Error loading from database (F-001 error handling)
                print("Error loading flower: \(error)")
                self.errorMessage = "Flower not loaded. Try again."
                self.isLoading = false
                return
            }
        }
        
        // Fallback: Create default flower if no context (for previews/testing)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.isLoading = false
            if self.currentFlower == nil {
                let fallbackFlower = Flower(
                    name: "Daily Flower",
                    imageName: "flower_red_bloomed",
                    isCurrent: true,
                    isActive: true,
                    isOwned: true,
                    health: 100.0,
                    maxHealth: 100.0,
                    careLevel: 1.0,
                    questionGenre: QuestionGenre.relationship.rawValue
                )
                self.currentFlower = fallbackFlower
            }
        }
    }
    
    // Update partner status based on today's care entries (F-004)
    @MainActor
    func updatePartnerStatus() {
        guard let context = modelContext,
              let flower = currentFlower else {
            partnerStatus = .notConnected
            return
        }
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            
            // Determine partner ID (the other user)
            let partnerId = currentUserId == "user1" ? "user2" : "user1"
            
            // Fetch all care entries and filter in Swift (simpler than complex predicate)
            let descriptor = FetchDescriptor<DailyCare>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            
            let allCareEntries = try context.fetch(descriptor)
            
            // Filter for today's care entries for this flower
            let todayCareEntries = allCareEntries.filter { care in
                care.flowerId == flower.id &&
                care.date >= today && care.date < tomorrow
            }
            
            // Check if partner has completed today's care
            let partnerCare = todayCareEntries.first { care in
                care.effectiveUserId == partnerId && care.isCompleted
            }
            
            if partnerCare != nil {
                partnerStatus = .completed
            } else {
                partnerStatus = .waiting
            }
        } catch {
            print("Error checking partner status: \(error)")
            partnerStatus = .waiting  // Default to waiting on error
        }
    }
    
    // Update flower health based on time since last care (depletion)
    @MainActor
    func updateFlowerHealth(flower: Flower) {
        guard let context = modelContext else { return }
        
        let now = Date()
        let lastCare = flower.lastCareDate ?? flower.createdAt
        let hoursSinceLastCare = now.timeIntervalSince(lastCare) / 3600.0
        
        // Health depletes based on care level and time
        // Higher care level = faster depletion
        // Depletion rate: careLevel * 0.5% per hour (so 1.0 = 0.5%/hr, 2.0 = 1%/hr, 3.0 = 1.5%/hr)
        let depletionAmount = hoursSinceLastCare * flower.effectiveCareLevel * 0.5
        
        let newHealth = max(0, min(flower.effectiveMaxHealth, flower.effectiveHealth - depletionAmount))
        flower.health = newHealth
        flower.maxHealth = flower.effectiveMaxHealth
        flower.careLevel = flower.effectiveCareLevel
        
        // Save updated health
        do {
            try context.save()
        } catch {
            print("Error updating flower health: \(error)")
        }
    }
    
    // Replenish health when care is completed
    @MainActor
    func replenishFlowerHealth(flower: Flower, amount: Double = 20.0) {
        guard let context = modelContext else { return }
        
        // Replenish health (default 20 points per care completion)
        let newHealth = min(flower.effectiveMaxHealth, flower.effectiveHealth + amount)
        flower.health = newHealth
        flower.maxHealth = flower.effectiveMaxHealth
        flower.careLevel = flower.effectiveCareLevel
        flower.lastCareDate = Date()
        
        // Save updated health
        do {
            try context.save()
        } catch {
            print("Error replenishing flower health: \(error)")
        }
    }
    
    // Calculate streak count based on consecutive days both users completed care (F-005, D-009)
    @MainActor
    func calculateStreak(flower: Flower) {
        guard let context = modelContext else {
            streakCount = 0
            return
        }
        
        do {
            // Fetch all QuestionHistory entries for this flower (these represent completed days)
            let descriptor = FetchDescriptor<QuestionHistory>(
                sortBy: [SortDescriptor(\.dateCompleted, order: .reverse)]
            )
            let allHistoryEntries = try context.fetch(descriptor)
            
            // Filter for this flower's history entries
            let flowerHistory = allHistoryEntries.filter { $0.flowerId == flower.id }
            
            guard !flowerHistory.isEmpty else {
                // No completed days yet, streak is 0
                flower.streakCount = 0
                flower.lastStreakDate = nil
                streakCount = 0
                try context.save()
                return
            }
            
            // Sort by date completed (most recent first)
            let sortedHistory = flowerHistory.sorted { $0.dateCompleted > $1.dateCompleted }
            
            // Calculate streak by checking consecutive days
            let calendar = Calendar.current
            var currentStreak = 0
            var lastCheckedDate: Date? = nil
            
            for entry in sortedHistory {
                let entryDate = calendar.startOfDay(for: entry.dateCompleted)
                
                if let lastDate = lastCheckedDate {
                    let daysBetween = calendar.dateComponents([.day], from: entryDate, to: lastDate).day ?? 0
                    
                    if daysBetween == 1 {
                        // Consecutive day, increment streak
                        currentStreak += 1
                        lastCheckedDate = entryDate
                    } else if daysBetween > 1 {
                        // Gap found, streak is broken
                        break
                    }
                    // If daysBetween == 0, it's the same day (shouldn't happen with sorted data, but skip it)
                } else {
                    // First entry (most recent completed day)
                    // Check if it's today or yesterday to start the streak
                    let today = calendar.startOfDay(for: Date())
                    let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                    
                    if entryDate == today || entryDate == yesterday {
                        // Can start/continue streak
                        currentStreak = 1
                        lastCheckedDate = entryDate
                    } else {
                        // Too old, streak is broken
                        break
                    }
                }
            }
            
            // Update flower's streak count
            flower.streakCount = currentStreak
            flower.lastStreakDate = lastCheckedDate
            streakCount = currentStreak
            
            // Save updated streak
            try context.save()
            
            print("✅ Streak calculated: \(currentStreak) days")
        } catch {
            print("Error calculating streak: \(error)")
            streakCount = 0
        }
    }
    
    // Update streak when both users complete care (called from FlowerCareSheetView)
    @MainActor
    func updateStreak(flower: Flower) {
        calculateStreak(flower: flower)
    }
    
    // Initialize default flowers (10 common flower types)
    @MainActor
    func initializeDefaultFlowers(context: ModelContext) {
        let flowerGenres: [String: String] = [
            "Rose": QuestionGenre.romantic.rawValue,
            "Tulip": QuestionGenre.informational.rawValue,
            "Daisy": QuestionGenre.fun.rawValue,
            "Sunflower": QuestionGenre.relationship.rawValue,
            "Lily": QuestionGenre.deep.rawValue,
            "Orchid": QuestionGenre.spicy.rawValue,
            "Peony": QuestionGenre.romantic.rawValue,
            "Lavender": QuestionGenre.deep.rawValue,
            "Marigold": QuestionGenre.fun.rawValue,
            "Carnation": QuestionGenre.relationship.rawValue
        ]
        
        // Check if flowers already exist
        let allFlowersDescriptor = FetchDescriptor<Flower>()
        guard let existingFlowers = try? context.fetch(allFlowersDescriptor) else { return }
        
        // Create flowers that don't exist yet
        for (flowerName, genre) in flowerGenres {
            let flowerExists = existingFlowers.contains { $0.name == flowerName }
            if !flowerExists {
                let newFlower = Flower(
                    name: flowerName,
                    imageName: "flower_red_bloomed",  // Use same image as daily flower
                    isCurrent: false,
                    isActive: false,  // Not active by default
                    isOwned: true,     // Owned but not active
                    health: 100.0,
                    maxHealth: 100.0,
                    careLevel: 1.0,
                    streakCount: 0,
                    questionGenre: genre
                )
                context.insert(newFlower)
            } else {
                // Migrate existing flowers to have a genre if they don't have one
                if let existingFlower = existingFlowers.first(where: { $0.name == flowerName }),
                   existingFlower.questionGenre == nil {
                    existingFlower.questionGenre = genre
                }
            }
        }
        
        // Migrate "Daily Flower" to have a genre if it doesn't have one
        if let dailyFlower = existingFlowers.first(where: { $0.name == "Daily Flower" }),
           dailyFlower.questionGenre == nil {
            dailyFlower.questionGenre = QuestionGenre.relationship.rawValue
        }
        
        // Save the new flowers
        do {
            try context.save()
            print("✅ Initialized default flowers")
        } catch {
            print("❌ Error initializing flowers: \(error)")
        }
    }
}

