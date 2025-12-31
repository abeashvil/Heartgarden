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
    @Query(sort: [SortDescriptor(\QuestionHistory.dateCompleted, order: .reverse)]) private var allHistoryEntries: [QuestionHistory]
    @Query private var allCareEntries: [DailyCare]
    @Query private var allChatMessages: [ChatMessage]
    
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
                    .frame(width: 40) // Narrow width, just enough for the circle
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTheme == .darkMode ? Color(red: 0.2, green: 0.2, blue: 0.2) : Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.leading, 18) // Slightly to the right to align with button
                    .padding(.top, buttonFrame != .zero ? buttonFrame.maxY + 5 : 0) // Position directly below button
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(1000)
                }
                
                if viewModel.isLoading {
                    ProgressView("Loading flower...")
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state (F-001 requirement)
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Try Again") {
                            viewModel.loadCurrentFlower()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let flower = viewModel.currentFlower {
                    // Content based on selected tab
                    if selectedTab == .main {
                        // Main flower display (F-001)
                        VStack(spacing: 0) {
                            // Garden button above flower - smaller height
                            Button(action: {
                                showGarden.toggle()
                            }) {
                                HStack {
                                    Text("Garden")
                                    Image(systemName: "chevron.down")
                                }
                                .font(.subheadline)
                                .foregroundColor(gardenButtonTextColor)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)  // Smaller height
                                .background(gardenButtonColor)
                                .cornerRadius(10)
                            }
                            .padding(.top, 20)
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            // Flower Image - centered in the middle with display enhancements
                            VStack(spacing: 10) {
                                flowerDisplayView(flower: flower)
                                
                                // Flower Name
                                Text(flower.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(primaryTextColor)
                                
                                // Health Bar
                                healthBarView(flower: flower)
                            }
                            
                            Spacer()
                            
                            // Bottom section with status boxes
                            VStack(spacing: 12) {
                                // Partner Status (F-004 placeholder) - Same size as streak box
                                HStack(spacing: 12) {
                                    Image(systemName: partnerStatusIcon)
                                        .foregroundColor(partnerStatusColor)
                                    Text(partnerStatusText)
                                        .font(.subheadline)
                                        .foregroundColor(primaryTextColor)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(transparentBoxBackground)
                                .cornerRadius(10)
                                
                                // Streak Count (F-005 placeholder) - Same size as partner status box
                                HStack(spacing: 8) {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                    Text("\(viewModel.streakCount) day streak")
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
                    } else {
                        // History view
                        HistoryView(selectedTheme: selectedTheme, currentUserId: currentUserId)
                            .padding(.bottom, 80)  // Extra padding for tab bar
                    }
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
                // DEBUG: User switching button for testing
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
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
                GardenView(selectedTheme: selectedTheme)
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
                if let flower = viewModel.currentFlower {
                    FlowerCareSheetView(flower: flower, selectedTheme: selectedTheme, currentUserId: currentUserId)
                        .environment(\.modelContext, modelContext)
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
            // Update partner status when view appears
            Task { @MainActor in
                viewModel.updatePartnerStatus()
            }
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
            
            // Main flower image with subtle parallax effect
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

// Placeholder Garden View (will be fully implemented in B-007)
struct GardenView: View {
    let selectedTheme: AppTheme
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
                
                VStack {
                    Text("Your Garden")
                        .font(.title)
                        .foregroundColor(primaryTextColor)
                        .padding()
                    Text("No flowers yet")
                        .foregroundColor(selectedTheme == .darkMode ? Color.gray.opacity(0.7) : Color.gray)
                        .padding()
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

#Preview {
    ContentView()
}

