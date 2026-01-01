//
//  ProfileEditView.swift
//  Flower App
//
//  Created for profile editing functionality
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ProfileEditView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Binding var showSettings: Bool  // Keep for compatibility but not actively used
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var userSettings: [UserSettings]
    @Query private var coupleLevels: [CoupleLevel]
    @Query(sort: [SortDescriptor(\Achievement.category, order: .forward), SortDescriptor(\Achievement.requirement, order: .forward)]) private var allAchievements: [Achievement]
    @Query(sort: [SortDescriptor(\Flower.createdAt, order: .reverse)]) private var allFlowers: [Flower]
    
    @State private var profilePicture: UIImage?
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var showPhotoOptions = false
    
    // Track original values to detect changes
    @State private var originalProfilePicture: UIImage?
    @State private var originalPhoneNumber: String = ""
    @State private var originalEmail: String = ""
    
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
    
    private var coupleLevel: CoupleLevel {
        if let level = coupleLevels.first {
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
    
    // Check if profile has been modified
    private var hasChanges: Bool {
        // Check phone number
        if phoneNumber != originalPhoneNumber {
            return true
        }
        
        // Check email
        if email != originalEmail {
            return true
        }
        
        // Check profile picture (compare data)
        if let currentPicture = profilePicture,
           let originalPicture = originalProfilePicture {
            // Both exist - compare data
            if let currentData = currentPicture.jpegData(compressionQuality: 1.0),
               let originalData = originalPicture.jpegData(compressionQuality: 1.0) {
                if currentData != originalData {
                    return true
                }
            }
        } else if profilePicture != nil || originalProfilePicture != nil {
            // One is nil, other is not - changed
            return true
        }
        
        return false
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Picture Section
                        VStack(spacing: 16) {
                            Text("Profile Picture")
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                            
                            // Profile picture display/edit
                            Button(action: {
                                showPhotoOptions = true
                            }) {
                                ZStack {
                                    if let profilePicture = profilePicture {
                                        Image(uiImage: profilePicture)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(primaryTextColor.opacity(0.4))
                                    }
                                    
                                    // Edit overlay
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.blue)
                                                .clipShape(Circle())
                                                .padding(8)
                                        }
                                    }
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 2)
                                )
                            }
                            
                            Text("Tap to change photo")
                                .font(.caption)
                                .foregroundColor(primaryTextColor.opacity(0.6))
                        }
                        .padding(.top, 20)
                        
                        // Phone Number Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Phone Number")
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(transparentBoxBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                                .keyboardType(.phonePad)
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal)
                        
                        // Email Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                            
                            TextField("Enter email address", text: $email)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(transparentBoxBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal)
                        
                        // Achievements Section
                        achievementsSection
                            .padding(.horizontal)
                        
                        // Bottom padding to account for floating button
                        if hasChanges {
                            Spacer()
                                .frame(height: 80)
                        } else {
                            Spacer()
                                .frame(height: 30)
                        }
                    }
                }
                
                // Floating Save Changes button
                if hasChanges {
                    VStack {
                        Spacer()
                        Button(action: {
                            saveProfile()
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: -2)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .foregroundColor(primaryTextColor)
                        .font(.headline)
                }
            }
            .onAppear {
                loadProfile()
                initializeAchievements()
                updateAchievements()
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhoto,
                matching: .images
            )
            .onChange(of: selectedPhoto) {
                Task {
                    if let newItem = selectedPhoto,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        profilePicture = uiImage
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $cameraImage)
            }
            .onChange(of: cameraImage) {
                if let image = cameraImage {
                    profilePicture = image
                }
            }
            .onChange(of: phoneNumber) {
                // Trigger view update to show/hide save button
            }
            .onChange(of: email) {
                // Trigger view update to show/hide save button
            }
            .onChange(of: profilePicture) {
                // Trigger view update to show/hide save button
            }
            .confirmationDialog("Change Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        showCamera = true
                    }
                }
                Button("Choose from Library") {
                    showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
    
    // Level summary card (condensed)
    private var levelSummaryCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                Text("Level \(coupleLevel.level)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text("\(coupleLevel.totalExperience) XP")
                    .font(.subheadline)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * coupleLevel.progressToNextLevel, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
    }
    
    // Achievements section with side-scrolling
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)
            
            // Level summary
            levelSummaryCard
            
            // Side-scrolling achievement categories
            let categories = ["level", "streak", "flowers", "questions"]
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        achievementCategoryCard(category: category)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // Achievement category card (side-scrollable)
    private func achievementCategoryCard(category: String) -> some View {
        let categoryAchievements = allAchievements.filter { $0.category == category }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(category.capitalized)
                .font(.headline)
                .foregroundColor(primaryTextColor)
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(categoryAchievements) { achievement in
                        achievementRow(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
    }
    
    // Condensed achievement row
    private func achievementRow(achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: achievement.isUnlocked ? "trophy.fill" : "trophy")
                .font(.system(size: 18))
                .foregroundColor(achievement.isUnlocked ? .yellow : .gray)
                .frame(width: 24)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(primaryTextColor)
                
                if !achievement.isUnlocked {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * achievement.progressPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    Text("\(achievement.currentProgress) / \(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.6))
                } else {
                    Text("Unlocked!")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
    }
    
    private func loadProfile() {
        let settings = self.settings
        
        // Load profile picture
        if let pictureData = settings.profilePicture(for: currentUserId),
           let uiImage = UIImage(data: pictureData) {
            profilePicture = uiImage
            originalProfilePicture = uiImage
        } else {
            profilePicture = nil
            originalProfilePicture = nil
        }
        
        // Load phone number
        let phone = settings.phoneNumber(for: currentUserId) ?? ""
        phoneNumber = phone
        originalPhoneNumber = phone
        
        // Load email
        let emailAddress = settings.email(for: currentUserId) ?? ""
        email = emailAddress
        originalEmail = emailAddress
    }
    
    private func saveProfile() {
        let settings = self.settings
        
        // Save profile picture
        if let profilePicture = profilePicture {
            let imageData = profilePicture.jpegData(compressionQuality: 0.8)
            settings.setProfilePicture(imageData, for: currentUserId)
            originalProfilePicture = profilePicture
        } else {
            settings.setProfilePicture(nil, for: currentUserId)
            originalProfilePicture = nil
        }
        
        // Save phone number
        settings.setPhoneNumber(phoneNumber.isEmpty ? nil : phoneNumber, for: currentUserId)
        originalPhoneNumber = phoneNumber
        
        // Save email
        settings.setEmail(email.isEmpty ? nil : email, for: currentUserId)
        originalEmail = email
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving profile: \(error)")
        }
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
            let flowerCount = allFlowers.filter { $0.effectiveIsOwned }.count
            for achievement in allAchievements.filter({ $0.category == "flowers" }) {
                let _ = achievement.updateProgress(flowerCount)
            }
            
            // Update question achievements (count from history)
            let questionCount = 0  // TODO: Count from QuestionHistory if needed
            
            for achievement in allAchievements.filter({ $0.category == "questions" }) {
                let _ = achievement.updateProgress(questionCount)
            }
            
            try modelContext.save()
        } catch {
            print("❌ Error updating achievements: \(error)")
        }
    }
}
