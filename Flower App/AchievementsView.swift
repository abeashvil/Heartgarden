//
//  AchievementsView.swift
//  Flower App
//
//  Created for displaying couple achievements and level-based data
//

import SwiftUI
import SwiftData

struct AchievementsView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.modelContext) private var modelContext
    @Query private var coupleLevels: [CoupleLevel]
    @Query(sort: [SortDescriptor(\Achievement.category, order: .forward), SortDescriptor(\Achievement.requirement, order: .forward)]) private var allAchievements: [Achievement]
    @Query(sort: [SortDescriptor(\Flower.createdAt, order: .reverse)]) private var allFlowers: [Flower]
    
    private var coupleLevel: CoupleLevel {
        if let level = coupleLevels.first {
            // Migrate existing level: ensure guaranteedQuestionsPerUser is set (for existing data)
            if level.guaranteedQuestionsPerUser == nil || level.guaranteedQuestionsPerUser! <= 0 {
                level.guaranteedQuestionsPerUser = 2
                do {
                    try modelContext.save()
                } catch {
                    print("Error migrating CoupleLevel: \(error)")
                }
            }
            return level
        } else {
            let newLevel = CoupleLevel()
            modelContext.insert(newLevel)
            do {
                try modelContext.save()
            } catch {
                print("Error creating CoupleLevel: \(error)")
            }
            return newLevel
        }
    }
    
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
    
    var body: some View {
        ZStack {
            // Background with theme color
            selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Level summary card
                    levelSummaryCard
                    
                    // Achievements by category
                    achievementsByCategory
                }
                .padding()
            }
        }
        .onAppear {
            initializeAchievements()
            updateAchievements()
        }
    }
    
    // Level summary card
    private var levelSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
                Text("Level \(coupleLevel.level)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
            }
            
            Text("\(coupleLevel.totalExperience) Total Experience")
                .font(.subheadline)
                .foregroundColor(primaryTextColor.opacity(0.7))
            
            // Progress to next level
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress to Level \(coupleLevel.level + 1)")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                    Spacer()
                    Text("\(coupleLevel.experience) / \(coupleLevel.experienceNeededForNextLevel) XP")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * coupleLevel.progressToNextLevel, height: 12)
                    }
                }
                .frame(height: 12)
            }
            
            // Stats
            HStack(spacing: 20) {
                VStack {
                    Text("\(coupleLevel.questionsAvailable)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    Text("Questions/Day")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
                
                Spacer()
                
                VStack {
                    Text("\(unlockedFlowersCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    Text("Flowers")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
                
                Spacer()
                
                VStack {
                    Text("\(unlockedAchievementsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    Text("Achievements")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
            }
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(16)
    }
    
    // Achievements by category
    private var achievementsByCategory: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)
                .padding(.horizontal)
            
            let categories = ["level", "streak", "flowers", "questions"]
            
            ForEach(categories, id: \.self) { category in
                achievementCategorySection(category: category)
            }
        }
    }
    
    // Achievement category section
    @ViewBuilder
    private func achievementCategorySection(category: String) -> some View {
        let categoryAchievements = allAchievements.filter { $0.category == category }
        
        if !categoryAchievements.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(category.capitalized)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal)
                
                ForEach(categoryAchievements) { achievement in
                    achievementCard(achievement: achievement)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // Achievement card
    private func achievementCard(achievement: Achievement) -> some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.yellow.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: achievement.isUnlocked ? "trophy.fill" : "trophy")
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                
                Text(achievement.achievementDescription)
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
                
                // Progress bar
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * achievement.progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(achievement.currentProgress) / \(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.6))
                } else {
                    Text("Unlocked!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
    }
    
    // Helper computed properties
    private var unlockedFlowersCount: Int {
        allFlowers.filter { $0.effectiveIsOwned }.count
    }
    
    private var unlockedAchievementsCount: Int {
        allAchievements.filter { $0.isUnlocked }.count
    }
    
    // Initialize achievements
    private func initializeAchievements() {
        let achievementDefinitions: [(id: String, title: String, achievementDescription: String, category: String, requirement: Int)] = [
            // Level achievements
            ("level_5", "Rising Stars", "Reach level 5", "level", 5),
            ("level_10", "Growing Together", "Reach level 10", "level", 10),
            ("level_20", "Strong Bond", "Reach level 20", "level", 20),
            ("level_50", "Unbreakable", "Reach level 50", "level", 50),
            
            // Streak achievements
            ("streak_7", "Week Warriors", "Maintain a 7-day streak", "streak", 7),
            ("streak_30", "Monthly Masters", "Maintain a 30-day streak", "streak", 30),
            ("streak_100", "Century Club", "Maintain a 100-day streak", "streak", 100),
            
            // Flower achievements
            ("flowers_5", "Garden Starter", "Unlock 5 flowers", "flowers", 5),
            ("flowers_10", "Flower Collector", "Unlock 10 flowers", "flowers", 10),
            ("flowers_20", "Master Gardener", "Unlock 20 flowers", "flowers", 20),
            
            // Question achievements
            ("questions_100", "Question Master", "Answer 100 questions", "questions", 100),
            ("questions_500", "Question Expert", "Answer 500 questions", "questions", 500),
            ("questions_1000", "Question Legend", "Answer 1000 questions", "questions", 1000),
        ]
        
        do {
            for def in achievementDefinitions {
                if allAchievements.first(where: { $0.achievementId == def.id }) == nil {
                    let achievement = Achievement(
                        achievementId: def.id,
                        title: def.title,
                        achievementDescription: def.achievementDescription,
                        category: def.category,
                        requirement: def.requirement
                    )
                    modelContext.insert(achievement)
                }
            }
            try modelContext.save()
        } catch {
            print("❌ Error initializing achievements: \(error)")
        }
    }
    
    // Update achievements based on current progress
    private func updateAchievements() {
        do {
            // Update level achievements
            for achievement in allAchievements.filter({ $0.category == "level" }) {
                let _ = achievement.updateProgress(coupleLevel.level)
            }
            
            // Update streak achievements
            let maxStreak = allFlowers.filter { $0.effectiveIsActive }
                .map { $0.effectiveStreakCount }
                .max() ?? 0
            
            for achievement in allAchievements.filter({ $0.category == "streak" }) {
                let _ = achievement.updateProgress(maxStreak)
            }
            
            // Update flower achievements
            let flowerCount = unlockedFlowersCount
            for achievement in allAchievements.filter({ $0.category == "flowers" }) {
                let _ = achievement.updateProgress(flowerCount)
            }
            
            // Update question achievements (count from history)
            let questionCount = allFlowers.compactMap { flower in
                // Count completed questions for this flower
                return 0  // TODO: Count from QuestionHistory
            }.reduce(0, +)
            
            for achievement in allAchievements.filter({ $0.category == "questions" }) {
                let _ = achievement.updateProgress(questionCount)
            }
            
            try modelContext.save()
        } catch {
            print("❌ Error updating achievements: \(error)")
        }
    }
}

