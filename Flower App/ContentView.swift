//
//  ContentView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData
import UIKit

// Theme color options
enum AppTheme: String, CaseIterable {
    case pastelRed = "Pastel Red"
    case pastelBlue = "Pastel Blue"
    case pastelGreen = "Pastel Green"
    case pastelYellow = "Pastel Yellow"
    case darkMode = "Dark Mode"
    
    var backgroundColor: Color {
        switch self {
        case .pastelRed:
            return Color(red: 1.0, green: 0.85, blue: 0.85) // Light pastel red
        case .pastelBlue:
            return Color(red: 0.85, green: 0.9, blue: 1.0) // Light pastel blue
        case .pastelGreen:
            return Color(red: 0.85, green: 0.95, blue: 0.85) // Light pastel green
        case .pastelYellow:
            return Color(red: 1.0, green: 0.98, blue: 0.8) // Light pastel yellow
        case .darkMode:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Dark background
        }
    }
}

// Tab selection enum
enum TabSelection {
    case main
    case history
    case index
    case profile
}

// Preference key for button frame tracking
struct ButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FlowerViewModel()
    @State private var showGarden = false
    @State private var selectedTheme: AppTheme = .pastelGreen
    @State private var showThemePicker = false
    @State private var showFlowerCare = false
    @State private var showHistory = false
    @State private var currentUserId: String = "user1"  // For testing: switch between user1 and user2
    @State private var showThemeDropdown = false
    @State private var buttonFrame: CGRect = .zero
    @State private var selectedTab: TabSelection = .main  // Track current tab
    @State private var pulseScale: CGFloat = 1.0  // For pulsing question indicator
    @State private var showStreakDebug = false
    @State private var currentActiveFlowerIndex: Int = 0  // Index of current active flower in swipe view
    @State private var showProfileEdit = false
    @State private var showSettings = false
    @Query(sort: [SortDescriptor(\QuestionHistory.dateCompleted, order: .reverse)]) private var allHistoryEntries: [QuestionHistory]
    @Query private var allCareEntries: [DailyCare]
    @Query private var allChatMessages: [ChatMessage]
    @Query(sort: [SortDescriptor(\Flower.createdAt, order: .reverse)]) private var allFlowers: [Flower]
    @Query private var coupleLevels: [CoupleLevel]
    @Query(sort: [SortDescriptor(\Achievement.category, order: .forward), SortDescriptor(\Achievement.requirement, order: .forward)]) private var allAchievements: [Achievement]
    @Query private var userSettings: [UserSettings]
    
    // Display enhancement states - scoped to flower view only
    @State private var flowerParticleOpacity: Double = 0.3
    @State private var flowerParticleScale: CGFloat = 0.8
    @State private var flowerParallaxOffset: CGSize = .zero
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                // Theme dropdown overlay
                if showThemeDropdown {
                    themeDropdownOverlay
                }
                
                // Main content
                if viewModel.isLoading {
                    ProgressView("Loading flower...")
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    tabContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Heartgarden")
                        .foregroundColor(primaryTextColor)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    themePickerButton
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .preference(key: ButtonFramePreferenceKey.self, value: geometry.frame(in: .global))
                            }
                        )
                }
                // Settings button
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Settings button
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 22))
                                .foregroundColor(primaryTextColor)
                        }
                        // DEBUG: User switching button for testing
                        Button(action: {
                            // Switch between user1 and user2
                            currentUserId = currentUserId == "user1" ? "user2" : "user1"
                            viewModel.currentUserId = currentUserId
                            print("Switched to: \(currentUserId)")
                            // Update partner status for new user
                            Task { @MainActor in
                                viewModel.updatePartnerStatus()
                            }
                        }) {
                            Text(currentUserId == "user1" ? "👤" : "👥")
                                .font(.title3)
                        }
                        // DEBUG: Streak testing button
                        Button(action: {
                            showStreakDebug.toggle()
                        }) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange.opacity(0.7))
                                .font(.caption)
                        }
                        // DEBUG: Temporary button to clear all data for testing
                        Button(action: {
                            clearAllData()
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
            .onAppear {
                updateNavigationBarAppearance()
            }
            .onChange(of: selectedTheme) {
                updateNavigationBarAppearance()
            }
            .onPreferenceChange(ButtonFramePreferenceKey.self) { frame in
                buttonFrame = frame
            }
            .background(
                // Close dropdown when tapping outside
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if showThemeDropdown {
                            withAnimation {
                                showThemeDropdown = false
                            }
                        }
                    }
            )
            .onTapGesture {
                // Close dropdown when tapping outside
                if showThemeDropdown {
                    showThemeDropdown = false
                }
            }
            .sheet(isPresented: $showGarden) {
                GardenView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                    .environment(\.modelContext, modelContext)
                    .onDisappear {
                        // Reload flower when garden view closes (in case user switched flowers)
                        Task { @MainActor in
                            viewModel.loadCurrentFlower()
                            if let flower = viewModel.currentFlower {
                                viewModel.calculateStreak(flower: flower)
                            }
                            viewModel.updatePartnerStatus()
                        }
                    }
            }
            .sheet(isPresented: $showStreakDebug) {
                StreakDebugView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                    .environment(\.modelContext, modelContext)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(selectedTheme: selectedTheme)
                    .environment(\.modelContext, modelContext)
            }
            .overlay(
                // Bottom tab bar
                VStack {
                    Spacer()
                    bottomTabBar
                }
                .ignoresSafeArea(edges: .bottom)
            )
            .sheet(isPresented: $showFlowerCare) {
                if let flower = currentActiveFlower {
                    FlowerCareSheetView(flower: flower, selectedTheme: selectedTheme, currentUserId: currentUserId)
                        .environment(\.modelContext, modelContext)
                }
            }
            .onAppear {
                // Initialize current flower index when view appears
                if let currentFlower = viewModel.currentFlower,
                   let index = activeFlowers.firstIndex(where: { $0.id == currentFlower.id }) {
                    currentActiveFlowerIndex = index
                } else if !activeFlowers.isEmpty {
                    currentActiveFlowerIndex = 0
                    if let firstFlower = activeFlowers.first {
                        switchToFlower(firstFlower)
                        viewModel.currentFlower = firstFlower
                    }
                }
            }
            .onChange(of: activeFlowers.count) { _ in
                // Update index when active flowers change
                if currentActiveFlowerIndex >= activeFlowers.count && !activeFlowers.isEmpty {
                    currentActiveFlowerIndex = activeFlowers.count - 1
                }
            }
        }
        .onAppear {
            // Set model context and load flower (F-001: loads on app open)
            if viewModel.modelContext == nil {
                viewModel.modelContext = modelContext
            }
            viewModel.currentUserId = currentUserId
            viewModel.loadCurrentFlower()
                    // Update partner status and streak when view appears
            Task { @MainActor in
                viewModel.updatePartnerStatus()
                if let flower = viewModel.currentFlower {
                    viewModel.calculateStreak(flower: flower)
                }
            }
            
            // Load and schedule reminders on app launch (B-009)
            loadAndScheduleReminders()
        }
        .onChange(of: currentUserId) { oldValue, newValue in
            // Update partner status when user switches
            viewModel.currentUserId = newValue
            Task { @MainActor in
                viewModel.updatePartnerStatus()
            }
        }
        .onChange(of: showFlowerCare) { oldValue, newValue in
            // Refresh partner status when flower care sheet closes (care might have been saved)
            if !newValue {
                Task { @MainActor in
                    viewModel.updatePartnerStatus()
                }
            }
        }
    }
    
    // Flower display view with enhancements
    @ViewBuilder
    private func flowerDisplayView(flower: Flower) -> some View {
        ZStack {
            // Soft shadow/glow behind the flower
            glowCircle
            
            // Particle effects (sparkles) - subtle animation
            ForEach(0..<6, id: \.self) { index in
                sparkleParticle(index: index)
            }
            
            // Main flower image with subtle parallax effect (includes pulsing indicator if needed)
            flowerImage(flower: flower)
        }
        .onAppear {
            // Only start animations when flower view appears
            // Use Task to ensure animations start on main thread
            Task { @MainActor in
                startFlowerAnimations()
            }
        }
    }
    
    // Check if partner has unanswered questions on this flower
    private func hasUnansweredPartnerQuestion(flower: Flower) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let partnerId = currentUserId == "user1" ? "user2" : "user1"
        
        // Get all questions partner asked on this flower today
        let partnerQuestions = allCareEntries.filter { care in
            care.flowerId == flower.id &&
            care.effectiveUserId == partnerId &&
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            care.questionText != nil &&
            !care.effectiveIsArchived
        }
        
        // Get all questions current user answered on this flower today
        let userAnswers = Set(allCareEntries.filter { care in
            care.flowerId == flower.id &&
            care.effectiveUserId == currentUserId &&
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            care.questionText != nil &&
            !care.effectiveIsArchived
        }.compactMap { $0.questionText })
        
        // Check if partner asked a question that user hasn't answered yet
        return partnerQuestions.contains { care in
            guard let questionText = care.questionText else { return false }
            return !userAnswers.contains(questionText)
        }
    }
    
    // Pulsing question indicator
    @ViewBuilder
    private func partnerQuestionIndicator() -> some View {
        ZStack {
            // Pulsing background circle
            Circle()
                .fill(Color.orange.opacity(0.2))
                .frame(width: 32, height: 32)
                .scaleEffect(pulseScale)
                .animation(
                    Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                    value: pulseScale
                )
            
            // Exclamation point icon
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
        }
        .onAppear {
            pulseScale = 1.2
        }
    }
    
    // Glow circle background
    private var glowCircle: some View {
        let glowColor = selectedTheme == .darkMode 
            ? Color.white.opacity(0.1) 
            : Color.black.opacity(0.05)
        
        return Circle()
            .fill(
                RadialGradient(
                    colors: [glowColor, Color.clear],
                    center: .center,
                    startRadius: 50,
                    endRadius: 120
                )
            )
            .frame(width: 240, height: 240)
            .blur(radius: 20)
    }
    
    // Sparkle particle
    @ViewBuilder
    private func sparkleParticle(index: Int) -> some View {
        let angle = Double(index) * .pi / 3
        Circle()
            .fill(Color.white.opacity(0.6))
            .frame(width: 4, height: 4)
            .offset(
                x: cos(angle) * 100,
                y: sin(angle) * 100
            )
            .opacity(flowerParticleOpacity)
            .scaleEffect(flowerParticleScale)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.1),
                value: flowerParticleOpacity
            )
    }
    
    // Main flower image
    @ViewBuilder
    private func flowerImage(flower: Flower) -> some View {
        let shadowColor = selectedTheme == .darkMode 
            ? Color.white.opacity(0.2) 
            : Color.black.opacity(0.15)
        
        ZStack {
            Image(flower.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .shadow(color: shadowColor, radius: 15, x: 0, y: 5)
                .offset(x: flowerParallaxOffset.width, y: flowerParallaxOffset.height)
                .animation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true),
                    value: flowerParallaxOffset
                )
            
        }
        .onTapGesture {
            showFlowerCare = true
        }
    }
    
    // Start flower animations - only affects flower view
    private func startFlowerAnimations() {
        // Start particle animation
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            flowerParticleOpacity = 0.7
            flowerParticleScale = 1.2
        }
        
        // Start parallax animation
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            flowerParallaxOffset = CGSize(width: 2, height: -2)
        }
    }
    
    // Transparent box background that blends with theme color
    private var transparentBoxBackground: some View {
        // Create a lighter, semi-transparent version that blends with background
        // Using white overlay to lighten the background color (or dark overlay for dark mode)
        ZStack {
            selectedTheme.backgroundColor
            if selectedTheme == .darkMode {
                Color.white.opacity(0.1) // Subtle light overlay for dark mode
            } else {
                Color.white.opacity(0.4) // Light overlay for pastel themes
            }
        }
    }
    
    // Day/night cycle lighting effect
    private var timeBasedLighting: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        // Day: 6 AM - 8 PM (bright), Night: 8 PM - 6 AM (dim)
        if hour >= 6 && hour < 20 {
            return Color.white.opacity(0.1) // Daytime - subtle bright overlay
        } else {
            return Color.black.opacity(0.1) // Nighttime - subtle dark overlay
        }
    }
    
    // DEBUG: Clear all data (questions, chats, history, and reset health)
    private func clearAllData() {
        do {
            // Clear all DailyCare entries (all answered questions)
            let careDescriptor = FetchDescriptor<DailyCare>()
            let careEntries = try modelContext.fetch(careDescriptor)
            for entry in careEntries {
                modelContext.delete(entry)
            }
            print("✅ Cleared \(careEntries.count) care entries")
            
            // Clear all ChatMessage entries (all chat messages)
            let chatDescriptor = FetchDescriptor<ChatMessage>()
            let chatMessages = try modelContext.fetch(chatDescriptor)
            for message in chatMessages {
                modelContext.delete(message)
            }
            print("✅ Cleared \(chatMessages.count) chat messages")
            
            // Clear all QuestionHistory entries (all archived questions)
            let historyDescriptor = FetchDescriptor<QuestionHistory>()
            let historyEntries = try modelContext.fetch(historyDescriptor)
            for history in historyEntries {
                modelContext.delete(history)
            }
            print("✅ Cleared \(historyEntries.count) history entries")
            
            // Reset flower health to 0
            if let flower = viewModel.currentFlower {
                flower.health = 0.0
                flower.maxHealth = flower.effectiveMaxHealth
                flower.careLevel = flower.effectiveCareLevel
                print("✅ Reset flower health to 0")
            }
            
            try modelContext.save()
            print("✅ All data cleared successfully")
            
            // Reload flower to refresh the view and update partner status
            viewModel.loadCurrentFlower()
            viewModel.updatePartnerStatus()
        } catch {
            print("❌ Error clearing data: \(error)")
        }
    }
    
    // Update navigation bar appearance based on theme
    private func updateNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(selectedTheme.backgroundColor)
        
        if selectedTheme == .darkMode {
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        } else {
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    // Primary text color based on theme
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white // White text for dark mode
        default:
            return Color.primary // Default text color for pastel themes
        }
    }
    
    // Get all active flowers
    private var activeFlowers: [Flower] {
        allFlowers.filter { flower in
            // Migrate existing flowers: if isActive is nil, check isCurrent as fallback
            if flower.isActive == nil {
                // Migrate: if isCurrent, mark as active and owned
                if flower.isCurrent {
                    flower.isActive = true
                    flower.isOwned = true
                    try? modelContext.save()
                    return true
                }
                return false
            }
            return flower.effectiveIsActive
        }
    }
    
    // Get current active flower based on index
    private var currentActiveFlower: Flower? {
        guard !activeFlowers.isEmpty else { return nil }
        let index = min(max(0, currentActiveFlowerIndex), activeFlowers.count - 1)
        return activeFlowers[index]
    }
    
    // Theme dropdown overlay
    @ViewBuilder
    private var themeDropdownOverlay: some View {
        VStack(spacing: 10) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    withAnimation {
                        selectedTheme = theme
                        showThemeDropdown = false
                    }
                }) {
                    Circle()
                        .fill(theme.backgroundColor)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(theme == selectedTheme ? Color.blue : Color.gray.opacity(0.3), lineWidth: theme == selectedTheme ? 3 : 1)
                        )
                        .overlay(
                            Group {
                                if theme == selectedTheme {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                }
            }
        }
        .padding(.vertical, 10)
        .frame(width: 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedTheme == .darkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 18)
        .padding(.top, buttonFrame != .zero ? buttonFrame.maxY + 5 : 0)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .opacity
        ))
        .zIndex(1000)
    }
    
    // Error view
    @ViewBuilder
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            Button("Try Again") {
                viewModel.loadCurrentFlower()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // Tab content view
    @ViewBuilder
    private var tabContent: some View {
        if selectedTab == .main {
            mainFlowerSwipeView
        } else if selectedTab == .history {
            HistoryView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                .padding(.bottom, 80)
        } else if selectedTab == .index {
            FlowerIndexView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                .padding(.bottom, 80)
        } else if selectedTab == .profile {
            ProfileEditView(selectedTheme: selectedTheme, currentUserId: currentUserId, showSettings: .constant(false))
                .padding(.bottom, 80)
        }
    }
    
    // Get or create couple level with migration handling
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
            // Reset questions if new day
            if level.shouldResetQuestions {
                level.resetDailyQuestions()
                do {
                    try modelContext.save()
                } catch {
                    print("Error resetting questions: \(error)")
                }
            }
            return level
        } else {
            // Create default level
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
    
    // Level bar view
    @ViewBuilder
    private var levelBarView: some View {
        let level = coupleLevel
        let progress = level.progressToNextLevel
        
        VStack(spacing: 4) {
            HStack {
                // Level number
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("Level \(level.level)")
                        .font(.headline)
                        .foregroundColor(primaryTextColor)
                }
                
                Spacer()
                
                // Experience info
                Text("\(level.experience) / \(level.experienceNeededForNextLevel) XP")
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                        .frame(height: 12)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
        )
    }
    
    // Garden button color based on theme
    private var gardenButtonColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.gray.opacity(0.3) // Light grey for dark mode
        default:
            return Color.green // Green for pastel themes
        }
    }
    
    // Garden button text color based on theme
    private var gardenButtonTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white // White text for dark mode
        default:
            return Color.white // White text for pastel themes
        }
    }
    
    // Helper function to calculate per-user question status
    private func calculatePerUserQuestionStatus(coupleLevel: CoupleLevel, today: Date) -> (userAsked: Int, partnerAsked: Int, userRemaining: Int) {
        let partnerId = currentUserId == "user1" ? "user2" : "user1"
        
        // Count only questions where the user was FIRST to answer (initiated the question)
        // Don't count questions where they answered their partner's question
        // IMPORTANT: Count ALL questions (including archived) to get accurate count
        let allQuestionsToday = allCareEntries.filter { care in
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            care.questionText != nil
        }
        
        // Group by flower and question text to find who asked first
        var userAsked = 0
        var partnerAsked = 0
        let questionGroups = Dictionary(grouping: allQuestionsToday) { care in
            "\(care.flowerId.uuidString)|\(care.questionText ?? "")"
        }
        
        for (_, careEntries) in questionGroups {
            // Sort by creation time to find who answered first
            let sortedEntries = careEntries.sorted { $0.createdAt < $1.createdAt }
            if let firstEntry = sortedEntries.first {
                if firstEntry.effectiveUserId == currentUserId {
                    userAsked += 1
                } else if firstEntry.effectiveUserId == partnerId {
                    partnerAsked += 1
                }
            }
        }
        
        // Calculate remaining for current user
        let totalAvailable = coupleLevel.questionsAvailable
        let basePerUser = totalAvailable / 2
        let hasExtra = totalAvailable % 2 == 1
        
        let userRemaining: Int
        if hasExtra {
            if userAsked >= basePerUser && partnerAsked < basePerUser {
                userRemaining = max(0, basePerUser + 1 - userAsked)
            } else if userAsked < basePerUser {
                userRemaining = basePerUser - userAsked
            } else {
                userRemaining = 0
            }
        } else {
            userRemaining = max(0, basePerUser - userAsked)
        }
        
        return (userAsked, partnerAsked, userRemaining)
    }
    
    // Questions remaining counter for main view - condensed style matching streak box
    @ViewBuilder
    private func questionsRemainingCounter(flower: Flower) -> some View {
        let coupleLevel: CoupleLevel = {
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
        }()
        let today = Calendar.current.startOfDay(for: Date())
        
        // Calculate per-user question status
        let (userAsked, partnerAsked, userRemaining) = calculatePerUserQuestionStatus(coupleLevel: coupleLevel, today: today)
        let totalAvailable = coupleLevel.questionsAvailable
        let basePerUser = totalAvailable / 2
        let hasExtra = totalAvailable % 2 == 1
        
        // Calculate limits for display
        let userTotalLimit = hasExtra && userAsked >= basePerUser && partnerAsked < basePerUser 
            ? basePerUser + 1 
            : basePerUser
        
        let partnerTotalLimit = hasExtra && partnerAsked >= basePerUser && userAsked < basePerUser 
            ? basePerUser + 1 
            : basePerUser
        
        let partnerRemaining = max(0, partnerTotalLimit - partnerAsked)
        
        // Condensed single-line display matching streak box style
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.blue)
            Text("\(userRemaining)/\(userTotalLimit) • Partner: \(partnerRemaining)/\(partnerTotalLimit)")
                .font(.subheadline)
                .foregroundColor(primaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(transparentBoxBackground)
        .cornerRadius(10)
    }
    
    // Health bar view
    @ViewBuilder
    private func healthBarView(flower: Flower) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(healthColor(percentage: flower.healthPercentage))
                    .font(.caption)
                Text("\(Int(flower.effectiveHealth)) / \(Int(flower.effectiveMaxHealth))")
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.8))
            }
            
            // Health bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                        .frame(height: 8)
                    
                    // Health fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(healthColor(percentage: flower.healthPercentage))
                        .frame(width: geometry.size.width * flower.healthPercentage, height: 8)
                        .animation(.easeInOut, value: flower.healthPercentage)
                }
            }
            .frame(height: 8)
            .frame(width: 200)
        }
    }
    
    // Health color based on percentage
    private func healthColor(percentage: Double) -> Color {
        if percentage > 0.6 {
            return .green
        } else if percentage > 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Partner status helpers
    private var partnerStatusIcon: String {
        switch viewModel.partnerStatus {
        case .completed:
            return "checkmark.circle.fill"
        case .waiting:
            return "clock.fill"
        case .notConnected:
            return "person.crop.circle.badge.questionmark"
        }
    }
    
    private var partnerStatusColor: Color {
        switch viewModel.partnerStatus {
        case .completed:
            return .green
        case .waiting:
            return .orange
        case .notConnected:
            return .gray
        }
    }
    
    private var partnerStatusText: String {
        switch viewModel.partnerStatus {
        case .completed:
            return "Partner completed today's care"
        case .waiting:
            return "Waiting for partner"
        case .notConnected:
            return "Partner not connected"
        }
    }
    
    // Theme picker button with dropdown
    private var themePickerButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                showThemeDropdown.toggle()
            }
        }) {
            Image(systemName: "paintpalette.fill")
                .foregroundColor(primaryTextColor)
        }
    }
    
    // Check if there are any unread history entries
    private var hasUnreadHistory: Bool {
        for entry in allHistoryEntries {
            let user1Care = allCareEntries.first { $0.id == entry.user1CareId }
            let user2Care = allCareEntries.first { $0.id == entry.user2CareId }
            
            // Determine partner's care entry
            let partnerCare = (user1Care?.effectiveUserId == currentUserId ? user2Care : user1Care)
            let partnerId = currentUserId == "user1" ? "user2" : "user1"
            
            // Get last viewed date for current user
            // If nil, user has never viewed it, so it's unread
            guard let lastViewed = entry.lastViewedDate(for: currentUserId) else {
                return true  // Never viewed = unread
            }
            
            // Check if partner has sent new chat messages since last viewed
            let careIds: Set<UUID> = {
                var ids: Set<UUID> = []
                if let user1Care = user1Care { ids.insert(user1Care.id) }
                if let user2Care = user2Care { ids.insert(user2Care.id) }
                return ids
            }()
            
            let unreadChatMessages = allChatMessages.filter { message in
                careIds.contains(message.careId) &&
                message.effectiveUserId == partnerId &&
                message.createdAt > lastViewed
            }
            
            // Also check if partner answered after user last viewed (for new questions)
            let partnerAnsweredAfterView = partnerCare?.createdAt ?? Date.distantPast > lastViewed
            
            if !unreadChatMessages.isEmpty || partnerAnsweredAfterView {
                return true
            }
        }
        return false
    }
    
    // Main flower swipe view
    private var mainFlowerSwipeView: some View {
        Group {
            if let flower = currentActiveFlower {
                VStack(spacing: 0) {
                    // Level bar at the top
                    levelBarView
                        .padding(.top, 10)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Flower Image - centered in the middle with display enhancements
                    VStack(spacing: 10) {
                        flowerDisplayView(flower: flower)
                        
                        // Flower Name with question indicator
                        HStack {
                            Spacer()
                            Text(flower.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(primaryTextColor)
                                .overlay(alignment: .trailing) {
                                    if hasUnansweredPartnerQuestion(flower: flower) {
                                        partnerQuestionIndicator()
                                            .offset(x: 32)
                                    }
                                }
                            Spacer()
                        }
                        .frame(height: 32) // Fixed height to prevent layout shifts
                        
                        // Health Bar
                        healthBarView(flower: flower)
                        
                        // Flower indicator (e.g., "1 of 3")
                        if activeFlowers.count > 1 {
                            HStack(spacing: 4) {
                                ForEach(0..<activeFlowers.count, id: \.self) { index in
                                    Circle()
                                        .fill(index == currentActiveFlowerIndex ? primaryTextColor : primaryTextColor.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let horizontalAmount = value.translation.width
                                let verticalAmount = value.translation.height
                                
                                // Determine swipe direction (prioritize horizontal)
                                if abs(horizontalAmount) > abs(verticalAmount) {
                                    if horizontalAmount > 50 {
                                        // Swipe right - previous flower
                                        withAnimation {
                                            if currentActiveFlowerIndex > 0 {
                                                currentActiveFlowerIndex -= 1
                                                switchToFlower(activeFlowers[currentActiveFlowerIndex])
                                            }
                                        }
                                    } else if horizontalAmount < -50 {
                                        // Swipe left - next flower
                                        withAnimation {
                                            if currentActiveFlowerIndex < activeFlowers.count - 1 {
                                                currentActiveFlowerIndex += 1
                                                switchToFlower(activeFlowers[currentActiveFlowerIndex])
                                            }
                                        }
                                    }
                                }
                            }
                    )
                    
                    Spacer()
                    
                    // Bottom section with status boxes
                    VStack(spacing: 12) {
                        // Questions remaining - condensed style matching streak box
                        questionsRemainingCounter(flower: flower)
                        
                        // Streak Count (F-005)
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(flower.effectiveStreakCount) day streak")
                                .font(.subheadline)
                                .foregroundColor(primaryTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(transparentBoxBackground)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)  // Extra padding for tab bar
                }
                .padding()
                .onTapGesture {
                    // Tap flower to open care screen
                    showFlowerCare = true
                }
                .onAppear {
                    // Update viewModel when flower changes
                    viewModel.currentFlower = flower
                    viewModel.updatePartnerStatus()
                    if let flower = viewModel.currentFlower {
                        viewModel.calculateStreak(flower: flower)
                    }
                }
            } else {
                // No active flowers
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(primaryTextColor.opacity(0.5))
                    Text("No Active Flowers")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(primaryTextColor)
                    Text("Activate a flower from the Index to get started")
                        .font(.subheadline)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
    }
    
    // Switch to a different flower as current
    private func switchToFlower(_ flower: Flower) {
        do {
            // Set all active flowers to not current
            for f in activeFlowers {
                f.isCurrent = false
            }
            // Set selected flower as current
            flower.isCurrent = true
            try modelContext.save()
            print("✅ Switched to flower: \(flower.name)")
        } catch {
            print("❌ Error switching flower: \(error)")
        }
    }
    
    // Bottom tab bar
    private var bottomTabBar: some View {
        HStack(spacing: 0) {
            // Main page tab (flower icon)
            Button(action: {
                withAnimation {
                    selectedTab = .main
                }
            }) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == .main ? primaryTextColor : primaryTextColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            
            // Index page tab (book icon) - in the middle
            Button(action: {
                withAnimation {
                    selectedTab = .index
                }
            }) {
                Image(systemName: "book.fill")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == .index ? primaryTextColor : primaryTextColor.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            
            // History page tab (text box icon)
            Button(action: {
                withAnimation {
                    selectedTab = .history
                }
            }) {
                ZStack {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 24))
                        .foregroundColor(selectedTab == .history ? primaryTextColor : primaryTextColor.opacity(0.5))
                    
                    // Unread indicator
                    if hasUnreadHistory {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 12, y: -12)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            
            // Profile page tab (person icon)
            Button(action: {
                withAnimation {
                    selectedTab = .profile
                }
            }) {
                // Show profile picture if available, otherwise default icon
                if let settings = userSettings.first,
                   let pictureData = settings.profilePicture(for: currentUserId),
                   let uiImage = UIImage(data: pictureData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(selectedTab == .profile ? primaryTextColor : primaryTextColor.opacity(0.5), lineWidth: selectedTab == .profile ? 2 : 1)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(selectedTab == .profile ? primaryTextColor : primaryTextColor.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
        }
        .background(
            ZStack {
                Rectangle()
                    .fill(selectedTheme == .darkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white.opacity(0.7))
                Rectangle()
                    .fill(selectedTheme.backgroundColor.opacity(0.3))
            }
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
        )
        .ignoresSafeArea(edges: .bottom)
    }
    
    // Load and schedule reminders (B-009)
    private func loadAndScheduleReminders() {
        guard let settings = userSettings.first else { return }
        
        if settings.effectiveReminderEnabled {
            // Use default time (8 PM) - will be replaced with scenario-based scheduling
            NotificationManager.shared.scheduleDailyReminder(
                at: 20,
                minute: 0,
                isEnabled: true
            )
        } else {
            NotificationManager.shared.cancelAllReminders()
        }
    }
}

// Streak Debug View
struct StreakDebugView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allFlowers: [Flower]
    @Query private var allHistoryEntries: [QuestionHistory]
    @Query private var allCareEntries: [DailyCare]
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    private var currentFlower: Flower? {
        allFlowers.first { $0.isCurrent }
    }
    
    private var streakInfoSection: some View {
        Group {
            if let flower = currentFlower {
                VStack(spacing: 12) {
                    Text("Current Streak")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    
                    Text("\(flower.effectiveStreakCount) days")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    if let lastStreakDate = flower.lastStreakDate {
                        Text("Last streak date: \(lastStreakDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                )
            }
        }
    }
    
    private var historyEntriesSection: some View {
        Group {
            if let flower = currentFlower {
                historyEntriesList(flower: flower)
            }
        }
    }
    
    @ViewBuilder
    private func historyEntriesList(flower: Flower) -> some View {
        let flowerHistory = getFlowerHistory(flower: flower)
        
        VStack(alignment: .leading, spacing: 12) {
            Text("History Entries (\(flowerHistory.count))")
                .font(.headline)
                .foregroundColor(primaryTextColor)
            
            ForEach(Array(flowerHistory.enumerated()), id: \.element.id) { index, entry in
                let previousEntry = index > 0 ? flowerHistory[index - 1] : nil
                historyEntryRow(entry: entry, index: index, totalCount: flowerHistory.count, previousEntry: previousEntry)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
        )
    }
    
    private func getFlowerHistory(flower: Flower) -> [QuestionHistory] {
        return allHistoryEntries
            .filter { $0.flowerId == flower.id }
            .sorted { $0.dateCompleted > $1.dateCompleted }
    }
    
    @ViewBuilder
    private func historyEntryRow(entry: QuestionHistory, index: Int, totalCount: Int, previousEntry: QuestionHistory?) -> some View {
        let daysBetween = calculateDaysBetween(entry: entry, previousEntry: previousEntry)
        
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(totalCount - index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)
                Text(entry.dateCompleted, style: .date)
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            Spacer()
            if let days = daysBetween {
                Text("\(days) day gap")
                    .font(.caption)
                    .foregroundColor(days == 1 ? .green : .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.05) : Color.white.opacity(0.2))
        )
    }
    
    private func calculateDaysBetween(entry: QuestionHistory, previousEntry: QuestionHistory?) -> Int? {
        guard let previous = previousEntry else { return nil }
        let calendar = Calendar.current
        let entryDate = calendar.startOfDay(for: entry.dateCompleted)
        let previousDate = calendar.startOfDay(for: previous.dateCompleted)
        let components = calendar.dateComponents([.day], from: entryDate, to: previousDate)
        return components.day
    }
    
    private var debugContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                streakInfoSection
                historyEntriesSection
                testActionsSection
            }
            .padding()
        }
    }
    
    private var testActionsSection: some View {
        VStack(spacing: 12) {
            Text("Test Actions")
                .font(.headline)
                .foregroundColor(primaryTextColor)
            
            Button(action: {
                createTestStreakData(days: 3)
            }) {
                Text("Create 3-Day Streak")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            
            Button(action: {
                createTestStreakData(days: 5, withGap: true)
            }) {
                Text("Create Streak with Gap (Resets)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            
            Button(action: {
                recalculateStreak()
            }) {
                Text("Recalculate Streak")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
        )
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                debugContent
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Streak Debug")
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
        }
    }
    
    // Create test streak data
    private func createTestStreakData(days: Int, withGap: Bool = false) {
        guard let flower = currentFlower else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<days {
            // If withGap, skip day 2 to create a gap
            if withGap && i == 1 {
                continue
            }
            
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            
            // Create test care entries for both users
            let user1Care = DailyCare(
                flowerId: flower.id,
                userId: "user1",
                date: date,
                answerText: "Test answer user1 day \(i + 1)",
                isCompleted: true,
                questionText: "Test question \(i + 1)"
            )
            
            let user2Care = DailyCare(
                flowerId: flower.id,
                userId: "user2",
                date: date,
                answerText: "Test answer user2 day \(i + 1)",
                isCompleted: true,
                questionText: "Test question \(i + 1)"
            )
            
            // Create history entry
            let history = QuestionHistory(
                flowerId: flower.id,
                questionText: "Test question \(i + 1)",
                dateCompleted: date,
                user1CareId: user1Care.id,
                user2CareId: user2Care.id
            )
            
            modelContext.insert(user1Care)
            modelContext.insert(user2Care)
            modelContext.insert(history)
        }
        
        do {
            try modelContext.save()
            print("✅ Created test streak data: \(days) days")
            recalculateStreak()
        } catch {
            print("❌ Error creating test data: \(error)")
        }
    }
    
    // Recalculate streak
    private func recalculateStreak() {
        guard let flower = currentFlower else { return }
        
        Task { @MainActor in
            let viewModel = FlowerViewModel(modelContext: modelContext)
            viewModel.currentFlower = flower
            viewModel.calculateStreak(flower: flower)
        }
    }
}

// Theme Picker View
struct ThemePickerView: View {
    @Binding var selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                List {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            selectedTheme = theme
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(theme.backgroundColor)
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(primaryTextColor, lineWidth: theme == selectedTheme ? 3 : 1)
                                    )
                                Text(theme.rawValue)
                                    .foregroundColor(primaryTextColor)
                                Spacer()
                                if theme == selectedTheme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Choose Theme")
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
        }
    }
}

// Garden View (B-007: S-003 and F-007) - Shows active flowers only
struct GardenView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Flower.createdAt, order: .reverse)]) private var allFlowers: [Flower]
    @State private var showFlowerIndex = false
    
    // Filter to show only active flowers
    private var activeFlowers: [Flower] {
        allFlowers.filter { flower in
            // Migrate existing flowers: if isActive is nil, check isCurrent as fallback
            if flower.isActive == nil {
                // Migrate: if isCurrent, mark as active and owned
                if flower.isCurrent {
                    flower.isActive = true
                    flower.isOwned = true
                    try? modelContext.save()
                    return true
                }
                return false
            }
            return flower.effectiveIsActive
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
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                if activeFlowers.isEmpty {
                    // Empty state (F-007 error handling)
                    emptyGardenView
                } else {
                    // List of active flowers only
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(activeFlowers) { flower in
                                flowerCard(flower: flower)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Garden")
                        .foregroundColor(primaryTextColor)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showFlowerIndex = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                            Text("Index")
                        }
                        .foregroundColor(primaryTextColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
            .sheet(isPresented: $showFlowerIndex) {
                FlowerIndexView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                    .environment(\.modelContext, modelContext)
            }
        }
    }
    
    // Empty garden view (F-007: empty garden message)
    private var emptyGardenView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 60))
                .foregroundColor(primaryTextColor.opacity(0.5))
            Text("Your Garden is Empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)
            Text("Start caring for your flower to see it here")
                .font(.subheadline)
                .foregroundColor(primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Flower card in grid
    @ViewBuilder
    private func flowerCard(flower: Flower) -> some View {
        Button(action: {
            // Switch current flower
            switchToFlower(flower: flower)
        }) {
            VStack(spacing: 12) {
                // Flower image
                Image(flower.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .padding(.top, 8)
                
                // Flower name
                Text(flower.name)
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                // Current indicator
                if flower.isCurrent {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                
                // Health indicator
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(healthColor(percentage: flower.healthPercentage))
                    Text("\(Int(flower.effectiveHealth))/\(Int(flower.effectiveMaxHealth))")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.8))
                }
                
                // Streak indicator
                if flower.effectiveStreakCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(flower.effectiveStreakCount) day streak")
                            .font(.caption2)
                            .foregroundColor(primaryTextColor.opacity(0.8))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(transparentBoxBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(flower.isCurrent ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Health color based on percentage
    private func healthColor(percentage: Double) -> Color {
        if percentage >= 0.7 {
            return .green
        } else if percentage >= 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Switch to a different flower as current
    private func switchToFlower(flower: Flower) {
        do {
            // Set all active flowers to not current
            for f in activeFlowers {
                f.isCurrent = false
            }
            // Set selected flower as current
            flower.isCurrent = true
            try modelContext.save()
            print("✅ Switched to flower: \(flower.name)")
            dismiss()
        } catch {
            print("❌ Error switching flower: \(error)")
        }
    }
}

// Flower Index View - Shows all owned flower types
struct FlowerIndexView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Flower.name, order: .forward)]) private var allFlowers: [Flower]
    @Query private var userSettings: [UserSettings]
    @Query(sort: [SortDescriptor(\FlowerActivationRequest.createdAt, order: .reverse)]) private var allRequests: [FlowerActivationRequest]
    @State private var fadingOutFlowerId: UUID? = nil
    @State private var showUnlockScreen = false  // Track which flower is fading out
    @State private var selectedFlowerForGenre: Flower? = nil
    @State private var showGenreInfo = false
    
    // Filter to show only owned flowers, sorted with active flowers first
    private var ownedFlowers: [Flower] {
        let filtered = allFlowers.filter { flower in
            // Migrate existing flowers: if isOwned is nil, check if it exists as fallback
            if flower.isOwned == nil {
                // Migrate: mark existing flowers as owned
                flower.isOwned = true
                try? modelContext.save()
                return true
            }
            return flower.effectiveIsOwned
        }
        // Sort: active flowers first, then by name
        return filtered.sorted { flower1, flower2 in
            let isActive1 = flower1.effectiveIsActive
            let isActive2 = flower2.effectiveIsActive
            if isActive1 != isActive2 {
                return isActive1  // Active flowers come first
            }
            return flower1.name < flower2.name  // Then sort by name
        }
    }
    
    private var activeFlowerSlots: Int {
        let settings = userSettings.first ?? UserSettings(activeFlowerSlots: 3)
        if userSettings.isEmpty {
            // Create default settings if none exist with 3 slots
            let newSettings = UserSettings(activeFlowerSlots: 3)
            modelContext.insert(newSettings)
            try? modelContext.save()
            return 3
        }
        // Update to 3 slots if it's still 1
        if settings.effectiveActiveFlowerSlots < 3 {
            settings.activeFlowerSlots = 3
            try? modelContext.save()
            return 3
        }
        return settings.effectiveActiveFlowerSlots
    }
    
    private var activeFlowerCount: Int {
        allFlowers.filter { $0.effectiveIsActive }.count
    }
    
    // Get pending requests for the current user (requests from partner)
    private var pendingRequests: [FlowerActivationRequest] {
        let partnerId = currentUserId == "user1" ? "user2" : "user1"
        return allRequests.filter { request in
            request.isPending && request.requestedBy == partnerId
        }
    }
    
    // Get pending request for a specific flower
    private func pendingRequest(for flower: Flower) -> FlowerActivationRequest? {
        return allRequests.first { request in
            request.flowerId == flower.id && request.isPending
        }
    }
    
    // Check if current user has a pending request for a flower
    private func hasPendingRequest(for flower: Flower) -> Bool {
        return allRequests.contains { request in
            request.flowerId == flower.id && 
            request.isPending && 
            request.requestedBy == currentUserId
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
            
            if ownedFlowers.isEmpty {
                emptyIndexView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Active slots info
                        activeSlotsInfo
                        
                        // Unlock button
                        unlockButton
                        
                        // Pending requests section
                        if !pendingRequests.isEmpty {
                            pendingRequestsSection
                        }
                        
                        // List of all owned flowers
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(ownedFlowers) { flower in
                                flowerIndexCard(flower: flower)
                                    .opacity(fadingOutFlowerId == flower.id ? 0 : 1)
                                    .animation(.easeOut(duration: 0.3), value: fadingOutFlowerId)
                            }
                        }
                        .padding()
                    }
                    .padding(.top, 0)  // Remove top padding
                }
            }
        }
        .sheet(isPresented: $showUnlockScreen) {
            UnlockScreen(selectedTheme: selectedTheme)
                .environment(\.modelContext, modelContext)
        }
        .overlay(
            Group {
                if showGenreInfo, let flower = selectedFlowerForGenre {
                    FlowerGenreInfoView(flower: flower, selectedTheme: selectedTheme) {
                        showGenreInfo = false
                    }
                }
            }
        )
        .onAppear {
            initializeUnlockableFlowers()
            checkAndUnlockFlowers()
        }
    }
    
    // Initialize unlockable flowers with streak requirements
    private func initializeUnlockableFlowers() {
        // Define unlockable flowers with their streak requirements
        let unlockableFlowerData: [(name: String, imageName: String, streakRequirement: Int)] = [
            ("Cherry Blossom", "flower_red_bloomed", 7),
            ("Jasmine", "flower_red_bloomed", 14),
            ("Hibiscus", "flower_red_bloomed", 21),
            ("Magnolia", "flower_red_bloomed", 30),
            ("Azalea", "flower_red_bloomed", 45),
            ("Camellia", "flower_red_bloomed", 60),
            ("Wisteria", "flower_red_bloomed", 90),
            ("Gardenia", "flower_red_bloomed", 120),
            ("Plum Blossom", "flower_red_bloomed", 180),
            ("Lotus", "flower_red_bloomed", 365)
        ]
        
        do {
            for flowerData in unlockableFlowerData {
                // Check if flower already exists
                let existingFlower = allFlowers.first { $0.name == flowerData.name }
                
                if existingFlower == nil {
                    // Create new unlockable flower
                    let newFlower = Flower(
                        name: flowerData.name,
                        imageName: flowerData.imageName,
                        isCurrent: false,
                        isActive: false,
                        isOwned: false,  // Not owned yet
                        health: 100.0,
                        maxHealth: 100.0,
                        careLevel: 1.0,
                        streakCount: 0,
                        unlockRequirement: flowerData.streakRequirement,
                        unlockType: "streak"
                    )
                    modelContext.insert(newFlower)
                } else if existingFlower?.unlockRequirement == nil && !existingFlower!.effectiveIsOwned {
                    // Update existing flower to be unlockable if it's not already owned
                    existingFlower?.unlockRequirement = flowerData.streakRequirement
                    existingFlower?.unlockType = "streak"
                }
            }
            
            try modelContext.save()
            print("✅ Initialized unlockable flowers")
        } catch {
            print("❌ Error initializing unlockable flowers: \(error)")
        }
    }
    
    // Check and unlock flowers based on current streak
    private func checkAndUnlockFlowers() {
        let activeFlowers = allFlowers.filter { $0.effectiveIsActive }
        guard !activeFlowers.isEmpty else { return }
        
        let currentMaxStreak = activeFlowers.map { $0.effectiveStreakCount }.max() ?? 0
        
        for flower in allFlowers {
            if let requirement = flower.unlockRequirement,
               currentMaxStreak >= requirement,
               !flower.effectiveIsOwned {
                do {
                    flower.isOwned = true
                    flower.unlockRequirement = nil  // Mark as unlocked
                    try modelContext.save()
                    print("✅ Auto-unlocked flower: \(flower.name) (streak: \(currentMaxStreak) >= \(requirement))")
                } catch {
                    print("❌ Error auto-unlocking flower: \(error)")
                }
            }
        }
    }
    
    // Empty index view
    private var emptyIndexView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(primaryTextColor.opacity(0.5))
            Text("No Flowers Owned")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)
            Text("Unlock flowers through streaks or purchases")
                .font(.subheadline)
                .foregroundColor(primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Active slots info banner
    private var activeSlotsInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Flowers")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Text("\(activeFlowerCount) / \(activeFlowerSlots) slots used")
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            Spacer()
            if activeFlowerCount < activeFlowerSlots {
                Text("\(activeFlowerSlots - activeFlowerCount) available")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Text("All slots full")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 10)  // Remove top padding to eliminate whitespace
    }
    
    // Unlock button
    private var unlockButton: some View {
        Button(action: {
            showUnlockScreen = true
        }) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                Text("Unlock New Flowers")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
            }
            .foregroundColor(primaryTextColor)
            .padding()
            .background(transparentBoxBackground)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    // Pending requests section
    @ViewBuilder
    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Requests")
                .font(.headline)
                .foregroundColor(primaryTextColor)
                .padding(.horizontal)
            
            ForEach(pendingRequests) { request in
                if let flower = allFlowers.first(where: { $0.id == request.flowerId }) {
                    pendingRequestCard(request: request, flower: flower)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Pending request card
    @ViewBuilder
    private func pendingRequestCard(request: FlowerActivationRequest, flower: Flower) -> some View {
        HStack(spacing: 12) {
            // Flower image
            Image(flower.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flower.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(primaryTextColor)
                
                Text(request.requestType == "activate" ? "Activation requested" : "Deactivation requested")
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            
            Spacer()
            
            // Approve/Decline buttons
            HStack(spacing: 8) {
                Button(action: {
                    approveRequest(request: request, flower: flower)
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    declineRequest(request: request)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
    }
    
    // Flower card in index - clickable to toggle activation
    @ViewBuilder
    private func flowerIndexCard(flower: Flower) -> some View {
        ZStack {
            Button(action: {
                toggleFlowerActivation(flower: flower)
            }) {
                VStack(spacing: 12) {
                    // Flower image - fixed size
                    Image(flower.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.top, 8)
                    
                    // Flower name
                    Text(flower.name)
                        .font(.headline)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    
                    // Health indicator (if active) or waiting indicator (if request sent)
                    if flower.effectiveIsActive {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(healthColor(percentage: flower.healthPercentage))
                            Text("\(Int(flower.effectiveHealth))/\(Int(flower.effectiveMaxHealth))")
                                .font(.caption2)
                                .foregroundColor(primaryTextColor.opacity(0.8))
                        }
                    } else if hasPendingRequest(for: flower) {
                        // Show "Waiting for approval" indicator
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Waiting for approval")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    } else {
                        // Spacer to maintain consistent height
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.clear)
                            Text("")
                                .font(.caption2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(transparentBoxBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(strokeColor(for: flower), lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Top-right indicators (genre info and pending request)
            VStack {
                HStack {
                    Spacer()
                    // Genre info icon
                    Button(action: {
                        selectedFlowerForGenre = flower
                        showGenreInfo = true
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18))
                            .foregroundColor(primaryTextColor.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(8)
                }
                if hasPendingRequest(for: flower) {
                    HStack {
                        Spacer()
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(6)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Circle())
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                    }
                }
                Spacer()
            }
        }
    }
    
    // Health color based on percentage
    private func healthColor(percentage: Double) -> Color {
        if percentage >= 0.7 {
            return .green
        } else if percentage >= 0.3 {
            return .orange
        } else {
            return .red
        }
    }
    
    // Get stroke color for flower card
    private func strokeColor(for flower: Flower) -> Color {
        if flower.effectiveIsActive {
            return Color.green
        } else if hasPendingRequest(for: flower) {
            return Color.orange
        } else {
            return Color.clear
        }
    }
    
    // Toggle flower activation/deactivation - creates request instead of direct change
    private func toggleFlowerActivation(flower: Flower) {
        // Check if there's already a pending request from current user - if so, rescind it
        if let existingRequest = allRequests.first(where: { 
            $0.flowerId == flower.id && 
            $0.isPending && 
            $0.requestedBy == currentUserId 
        }) {
            // Rescind the request
            do {
                modelContext.delete(existingRequest)
                try modelContext.save()
                print("✅ Rescinded request for \(flower.name)")
            } catch {
                print("❌ Error rescinding request: \(error)")
            }
            return
        }
        
        do {
            let partnerId = currentUserId == "user1" ? "user2" : "user1"
            
            if flower.effectiveIsActive {
                // Check for existing partner request for deactivation
                let partnerDeactivateRequest = allRequests.first(where: {
                    $0.flowerId == flower.id &&
                    $0.isPending &&
                    $0.requestedBy == partnerId &&
                    $0.requestType == "deactivate"
                })
                
                // Always require approval for deactivation
                // If partner also requested deactivation, auto-approve both
                if let partnerRequest = partnerDeactivateRequest {
                    // Both want to deactivate - auto-approve
                    flower.isActive = false
                    // If this was the current flower, set another active flower as current
                    if flower.isCurrent {
                        let otherActiveFlowers = allFlowers.filter { $0.effectiveIsActive && $0.id != flower.id }
                        if let firstActive = otherActiveFlowers.first {
                            firstActive.isCurrent = true
                        } else {
                            flower.isCurrent = false
                        }
                    }
                    
                    // Mark both requests as approved
                    partnerRequest.status = "approved"
                    partnerRequest.respondedAt = Date()
                    partnerRequest.respondedBy = currentUserId
                    
                    try modelContext.save()
                    print("✅ Auto-approved deactivation for \(flower.name) (both users requested)")
                } else {
                    // Create deactivation request (requires partner approval)
                    let request = FlowerActivationRequest(
                        flowerId: flower.id,
                        requestedBy: currentUserId,
                        requestType: "deactivate"
                    )
                    modelContext.insert(request)
                    try modelContext.save()
                    print("✅ Deactivation request created for \(flower.name)")
                }
            } else {
                // Activate the flower
                guard activeFlowerCount < activeFlowerSlots else {
                    print("❌ No slots available")
                    return
                }
                
                // Check for existing partner request for activation
                let partnerActivateRequest = allRequests.first(where: {
                    $0.flowerId == flower.id &&
                    $0.isPending &&
                    $0.requestedBy == partnerId &&
                    $0.requestType == "activate"
                })
                
                // If partner also requested activation, auto-approve both
                if let partnerRequest = partnerActivateRequest {
                    // Both want to activate - auto-approve
                    // Fade out animation before activating
                    withAnimation(.easeOut(duration: 0.3)) {
                        fadingOutFlowerId = flower.id
                    }
                    
                    // Wait for fade out, then activate
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        flower.isActive = true
                        // If this is the first active flower, make it current
                        let activeFlowers = allFlowers.filter { $0.effectiveIsActive }
                        if activeFlowers.isEmpty {
                            flower.isCurrent = true
                        }
                        
                        // Mark both requests as approved
                        partnerRequest.status = "approved"
                        partnerRequest.respondedAt = Date()
                        partnerRequest.respondedBy = currentUserId
                        
                        do {
                            try modelContext.save()
                            fadingOutFlowerId = nil
                            print("✅ Auto-approved activation for \(flower.name) (both users requested)")
                        } catch {
                            print("❌ Error auto-approving activation: \(error)")
                            fadingOutFlowerId = nil
                        }
                    }
                } else {
                    // Create activation request (requires partner approval)
                    let request = FlowerActivationRequest(
                        flowerId: flower.id,
                        requestedBy: currentUserId,
                        requestType: "activate"
                    )
                    modelContext.insert(request)
                    try modelContext.save()
                    print("✅ Activation request created for \(flower.name)")
                }
            }
        } catch {
            print("❌ Error creating request: \(error)")
        }
    }
    
    // Approve a request
    private func approveRequest(request: FlowerActivationRequest, flower: Flower) {
        do {
            if request.requestType == "activate" {
                // Activate the flower
                guard activeFlowerCount < activeFlowerSlots else {
                    print("❌ No slots available")
                    declineRequest(request: request)
                    return
                }
                
                // Fade out animation before activating
                withAnimation(.easeOut(duration: 0.3)) {
                    fadingOutFlowerId = flower.id
                }
                
                // Wait for fade out, then activate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    flower.isActive = true
                    // If this is the first active flower, make it current
                    let activeFlowers = allFlowers.filter { $0.effectiveIsActive }
                    if activeFlowers.isEmpty {
                        flower.isCurrent = true
                    }
                    
                    request.status = "approved"
                    request.respondedAt = Date()
                    request.respondedBy = currentUserId
                    
                    do {
                        try modelContext.save()
                        fadingOutFlowerId = nil
                        print("✅ Approved activation for \(flower.name)")
                    } catch {
                        print("❌ Error approving request: \(error)")
                        fadingOutFlowerId = nil
                    }
                }
            } else {
                // Deactivate the flower
                flower.isActive = false
                // If this was the current flower, set another active flower as current
                if flower.isCurrent {
                    let otherActiveFlowers = allFlowers.filter { $0.effectiveIsActive && $0.id != flower.id }
                    if let firstActive = otherActiveFlowers.first {
                        firstActive.isCurrent = true
                    } else {
                        flower.isCurrent = false
                    }
                }
                
                request.status = "approved"
                request.respondedAt = Date()
                request.respondedBy = currentUserId
                
                try modelContext.save()
                print("✅ Approved deactivation for \(flower.name)")
            }
        } catch {
            print("❌ Error approving request: \(error)")
        }
    }
    
    // Decline a request
    private func declineRequest(request: FlowerActivationRequest) {
        do {
            request.status = "declined"
            request.respondedAt = Date()
            request.respondedBy = currentUserId
            try modelContext.save()
            print("✅ Declined request for flower")
        } catch {
            print("❌ Error declining request: \(error)")
        }
    }
}

// Unlock Screen (B-008: S-004) - Shows unlockable flowers and requirements
struct UnlockScreen: View {
    let selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Flower.unlockRequirement, order: .forward)]) private var allFlowers: [Flower]
    @State private var showUnlockAnimation = false
    @State private var unlockedFlowerId: UUID? = nil
    
    // Get unlockable flowers (those with unlock requirements)
    private var unlockableFlowers: [Flower] {
        allFlowers.filter { flower in
            flower.unlockRequirement != nil && !flower.effectiveIsOwned
        }
    }
    
    // Get maximum streak across all active flowers
    private var maxStreak: Int {
        let activeFlowers = allFlowers.filter { $0.effectiveIsActive }
        guard !activeFlowers.isEmpty else { return 0 }
        return activeFlowers.map { $0.effectiveStreakCount }.max() ?? 0
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
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                if unlockableFlowers.isEmpty {
                    emptyUnlockView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current streak info
                            currentStreakInfo
                            
                            // Unlockable flowers grid
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(unlockableFlowers) { flower in
                                    unlockableFlowerCard(flower: flower)
                                }
                            }
                            .padding()
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Unlock Flowers")
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
        }
        .onAppear {
            checkAndUnlockFlowers()
        }
    }
    
    // Current streak info banner
    private var currentStreakInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                Text("\(maxStreak) days")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 30))
                .foregroundColor(.orange)
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Empty unlock view
    private var emptyUnlockView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(primaryTextColor.opacity(0.5))
            Text("All Flowers Unlocked!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)
            Text("You've unlocked all available flowers")
                .font(.subheadline)
                .foregroundColor(primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // Unlockable flower card
    @ViewBuilder
    private func unlockableFlowerCard(flower: Flower) -> some View {
        let requirement = flower.unlockRequirement ?? 0
        let isUnlocked = maxStreak >= requirement
        let isUnlocking = unlockedFlowerId == flower.id
        
        VStack(spacing: 12) {
            // Flower image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(height: 120)
                    .background(transparentBoxBackground)
                
                if isUnlocking && showUnlockAnimation {
                    // Unlock animation
                    VStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)
                            .symbolEffect(.bounce, value: showUnlockAnimation)
                        Text("Unlocked!")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Image(flower.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .opacity(isUnlocked ? 1.0 : 0.3)
                        .overlay(
                            // Lock overlay for locked flowers
                            Group {
                                if !isUnlocked {
                                    ZStack {
                                        Color.black.opacity(0.5)
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        )
                }
            }
            
            // Flower name
            Text(flower.name)
                .font(.headline)
                .foregroundColor(primaryTextColor)
            
            // Unlock requirement
            HStack(spacing: 4) {
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Unlocked")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(requirement) day streak")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
            }
        }
        .padding()
        .background(transparentBoxBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.green : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            if isUnlocked && !flower.effectiveIsOwned {
                unlockFlower(flower: flower)
            }
        }
    }
    
    // Check and unlock flowers based on current streak
    private func checkAndUnlockFlowers() {
        let activeFlowers = allFlowers.filter { $0.effectiveIsActive }
        guard !activeFlowers.isEmpty else { return }
        
        let currentMaxStreak = activeFlowers.map { $0.effectiveStreakCount }.max() ?? 0
        
        for flower in unlockableFlowers {
            if let requirement = flower.unlockRequirement,
               currentMaxStreak >= requirement,
               !flower.effectiveIsOwned {
                unlockFlower(flower: flower, animated: true)
            }
        }
    }
    
    // Unlock a flower
    private func unlockFlower(flower: Flower, animated: Bool = false) {
        do {
            flower.isOwned = true
            flower.unlockRequirement = nil  // Mark as unlocked
            try modelContext.save()
            
            if animated {
                unlockedFlowerId = flower.id
                showUnlockAnimation = true
                
                // Hide animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showUnlockAnimation = false
                    unlockedFlowerId = nil
                }
            }
            
            print("✅ Unlocked flower: \(flower.name)")
        } catch {
            print("❌ Error unlocking flower: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

