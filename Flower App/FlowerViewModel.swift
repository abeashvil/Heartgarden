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
                    self.isLoading = false
                    return
                } else {
                    // No current flower found, create a default one
                    let defaultFlower = Flower(
                        name: "Daily Flower",
                        imageName: "Flower",
                        isCurrent: true
                    )
                    context.insert(defaultFlower)
                    try context.save()
                    self.currentFlower = defaultFlower
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
                self.currentFlower = Flower(
                    name: "Daily Flower",
                    imageName: "Flower",
                    isCurrent: true
                )
            }
        }
    }
}

