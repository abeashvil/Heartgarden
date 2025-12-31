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
                let descriptor = FetchDescriptor<Flower>(
                    predicate: #Predicate<Flower> { $0.isCurrent == true },
                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
                )
                let flowers = try context.fetch(descriptor)
                
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
                    // Update health based on time since last care
                    self.updateFlowerHealth(flower: flower)
                    // Update partner status after loading flower
                    self.updatePartnerStatus()
                    self.isLoading = false
                    return
                } else {
                    // No current flower found, create a default one
                    let defaultFlower = Flower(
                        name: "Daily Flower",
                        imageName: "Flower",
                        isCurrent: true,
                        health: 100.0,
                        maxHealth: 100.0,
                        careLevel: 1.0
                    )
                    // Ensure health properties are set
                    if defaultFlower.health == nil {
                        defaultFlower.health = 100.0
                        defaultFlower.maxHealth = 100.0
                        defaultFlower.careLevel = 1.0
                    }
                    context.insert(defaultFlower)
                    try context.save()
                    self.currentFlower = defaultFlower
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
                    imageName: "Flower",
                    isCurrent: true,
                    health: 100.0,
                    maxHealth: 100.0,
                    careLevel: 1.0
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
}

