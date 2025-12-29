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

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = FlowerViewModel()
    @State private var showGarden = false
    @State private var selectedTheme: AppTheme = .pastelGreen
    @State private var showThemePicker = false
    @State private var showFlowerCare = false
    
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
                    // Main flower display (F-001)
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Flower Image - centered in the middle with display enhancements
                        VStack(spacing: 10) {
                            flowerDisplayView(flower: flower)
                            
                            // Flower Name
                            Text(flower.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(primaryTextColor)
                        }
                        
                        Spacer()
                        
                        // Bottom section with boxes and button
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
                            
                            // Garden Dropdown Button (F-007)
                            Button(action: {
                                showGarden.toggle()
                            }) {
                                HStack {
                                    Text("Garden")
                                    Image(systemName: "chevron.down")
                                }
                                .font(.headline)
                                .foregroundColor(gardenButtonTextColor)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(gardenButtonColor)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                    .padding()
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
                    Button(action: {
                        showThemePicker.toggle()
                    }) {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(primaryTextColor)
                    }
                }
            }
            .onAppear {
                updateNavigationBarAppearance()
            }
            .onChange(of: selectedTheme) {
                updateNavigationBarAppearance()
            }
            .sheet(isPresented: $showGarden) {
                GardenView(selectedTheme: selectedTheme)
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerView(selectedTheme: $selectedTheme)
            }
            .sheet(isPresented: $showFlowerCare) {
                if let flower = viewModel.currentFlower {
                    FlowerCareView(flower: flower, selectedTheme: selectedTheme)
                }
            }
        }
        .onAppear {
            // Set model context and load flower (F-001: loads on app open)
            if viewModel.modelContext == nil {
                viewModel.modelContext = modelContext
            }
            viewModel.loadCurrentFlower()
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

