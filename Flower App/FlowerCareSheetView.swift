//
//  FlowerCareSheetView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData

// Wrapper view that decides whether to show care form or answer view
struct FlowerCareSheetView: View {
    let flower: Flower
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.modelContext) private var modelContext
    @Query private var todayCare: [DailyCare]
    
    // Check if current user has already answered today (get most recent unarchived answer)
    private var existingCare: DailyCare? {
        let today = Calendar.current.startOfDay(for: Date())
        return todayCare
            .filter { care in
                care.flowerId == flower.id &&
                care.effectiveUserId == currentUserId &&
                Calendar.current.isDate(care.date, inSameDayAs: today) &&
                !care.effectiveIsArchived
            }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    // Get partner's care entry (other user) - get most recent unarchived answer to match current user's answer
    private var partnerCare: DailyCare? {
        let today = Calendar.current.startOfDay(for: Date())
        let partnerId = currentUserId == "user1" ? "user2" : "user1"
        
        // Get partner's most recent unarchived answer (to match the current user's most recent answer)
        return todayCare
            .filter { care in
                care.flowerId == flower.id &&
                care.effectiveUserId == partnerId &&
                Calendar.current.isDate(care.date, inSameDayAs: today) &&
                !care.effectiveIsArchived
            }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    var body: some View {
        Group {
            // Check if flower is at full health
            if flower.effectiveHealth >= flower.effectiveMaxHealth {
                // Show full health message
                fullHealthView
            } else if let care = existingCare {
                // Show answer view if already answered
                FlowerAnswerView(
                    flower: flower,
                    care: care,
                    partnerCare: partnerCare,
                    currentUserId: currentUserId,
                    selectedTheme: selectedTheme
                )
            } else {
                // Show care form if not answered
                FlowerCareView(flower: flower, selectedTheme: selectedTheme, currentUserId: currentUserId)
            }
        }
        .id("\(existingCare?.id.uuidString ?? "none")-\(currentUserId)-\(flower.effectiveHealth)") // Force view update when care changes
        .onChange(of: todayCare) { oldValue, newValue in
            // Check if both users have answered their current questions and handle health/archiving
            checkAndHandleCompletedQuestions()
        }
    }
    
    // Full health view
    private var fullHealthView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Flower at Maximum Health!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)
            
            Text("Your flower is fully healthy and doesn't need any more care right now.")
                .font(.body)
                .foregroundColor(primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button("Done") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.green)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(selectedTheme.backgroundColor)
    }
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // Check if both users have answered their current questions and move to history
    private func checkAndHandleCompletedQuestions() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get each user's most recent unarchived answer
        let user1Answers = todayCare.filter { care in
            care.flowerId == flower.id &&
            care.effectiveUserId == "user1" &&
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            !care.effectiveIsArchived
        }.sorted { $0.createdAt > $1.createdAt }
        
        let user2Answers = todayCare.filter { care in
            care.flowerId == flower.id &&
            care.effectiveUserId == "user2" &&
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            !care.effectiveIsArchived
        }.sorted { $0.createdAt > $1.createdAt }
        
        // Process pairs of answers (both users have answered)
        let minCount = min(user1Answers.count, user2Answers.count)
        
        for i in 0..<minCount {
            let user1Care = user1Answers[i]
            let user2Care = user2Answers[i]
            
            guard let questionText = user1Care.questionText ?? user2Care.questionText else {
                continue
            }
            
            // Both users have answered this question pair - archive and move to history
            // Replenish health ONLY when both users have answered (40 points total for the pair)
            let newHealth = min(flower.effectiveMaxHealth, flower.effectiveHealth + 40.0)
            flower.health = newHealth
            flower.maxHealth = flower.effectiveMaxHealth
            flower.careLevel = flower.effectiveCareLevel
            flower.lastCareDate = Date()
            
            // Create history entry
            let history = QuestionHistory(
                flowerId: flower.id,
                questionText: questionText,
                dateCompleted: Date(),
                user1CareId: user1Care.id,
                user2CareId: user2Care.id
            )
            
            // Mark care entries as archived
            user1Care.isArchived = true
            user2Care.isArchived = true
            
            // Save changes
            do {
                modelContext.insert(history)
                try modelContext.save()
                print("✅ Question pair archived to history: \(questionText)")
                print("✅ Health replenished: \(flower.effectiveHealth)/\(flower.effectiveMaxHealth)")
            } catch {
                print("❌ Error archiving question: \(error)")
            }
        }
    }
}

// Query helper to fetch today's care entries
extension FlowerCareSheetView {
    init(flower: Flower, selectedTheme: AppTheme, currentUserId: String) {
        self.flower = flower
        self.selectedTheme = selectedTheme
        self.currentUserId = currentUserId
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        _todayCare = Query(
            filter: #Predicate<DailyCare> { care in
                care.date >= today && care.date < tomorrow
            },
            sort: \DailyCare.createdAt
        )
    }
}

