//
//  FlowerCareView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import PhotosUI

// Flower Care Screen (S-002) - F-002: Daily Question
struct FlowerCareView: View {
    let flower: Flower
    let selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var answerText: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var showPhotoPicker = false
    @State private var showImagePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Daily question system (F-002)
    private var dailyQuestion: String {
        // Get today's question based on day of year for variety
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let questionIndex = dayOfYear % dailyQuestions.count
        return dailyQuestions[questionIndex]
    }
    
    // Backup questions if something goes wrong (F-002 requirement)
    private let dailyQuestions = [
        "What made you smile today?",
        "What are you grateful for today?",
        "What's one thing you love about your partner?",
        "What's a memory that makes you happy?",
        "What are you looking forward to?",
        "What made today special?",
        "What's something you appreciate about your relationship?",
        "What's a small moment of joy you had today?",
        "What's something you're proud of?",
        "What's a goal you're working towards together?",
        "What's something that made you laugh today?",
        "What's a tradition you want to start?",
        "What's your favorite thing to do together?",
        "What's something new you learned about your partner?",
        "What's a dream you share?",
        "What's something that brings you closer?",
        "What's a challenge you've overcome together?",
        "What's something you want to try together?",
        "What's a place you want to visit together?",
        "What's something that makes your relationship unique?",
        "What's a habit you want to build together?",
        "What's something that surprised you today?",
        "What's a quality you admire in your partner?",
        "What's a moment you want to remember?",
        "What's something that made you feel loved today?",
        "What's a way you want to grow together?",
        "What's something that inspires you?",
        "What's a skill you want to learn together?",
    ]
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Flower image at top
                        Image(flower.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .padding(.top, 20)
                        
                        // Daily Question (F-002)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Question")
                                .font(.headline)
                                .foregroundColor(primaryTextColor.opacity(0.7))
                            
                            Text(dailyQuestion)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(primaryTextColor)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        
                        // Text Answer Box
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Answer")
                                .font(.headline)
                                .foregroundColor(primaryTextColor.opacity(0.7))
                            
                            TextEditor(text: $answerText)
                                .frame(minHeight: 120)
                                .padding(12)
                                .background(transparentBoxBackground)
                                .cornerRadius(12)
                                .foregroundColor(primaryTextColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Photo Button (F-003 placeholder)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a Photo")
                                .font(.headline)
                                .foregroundColor(primaryTextColor.opacity(0.7))
                            
                            Button(action: {
                                showPhotoPicker = true
                            }) {
                                HStack {
                                    if selectedPhotoData != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Photo Selected")
                                    } else {
                                        Image(systemName: "camera.fill")
                                        Text("Take or Choose Photo")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(transparentBoxBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Send Button
                        Button(action: {
                            sendCare()
                        }) {
                            Text("Send Care")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canSend ? Color.green : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!canSend)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Care for Flower")
                        .foregroundColor(primaryTextColor)
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(primaryTextColor)
                }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhoto,
                matching: .images
            )
            .onChange(of: selectedPhoto) {
                Task {
                    if let newItem = selectedPhoto,
                       let data = try? await newItem.loadTransferable(type: Data.self) {
                        selectedPhotoData = data
                    } else if selectedPhoto != nil {
                        showError = true
                        errorMessage = "Photo could not be loaded. Please try again."
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // Transparent box background
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
    
    // Check if can send (answer is required, photo is optional)
    private var canSend: Bool {
        !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Send care function
    private func sendCare() {
        // Validate answer
        guard !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError = true
            errorMessage = "Please provide an answer to the question."
            return
        }
        
        // TODO: In B-004, save answer and photo to database
        // For now, just show success and dismiss
        print("Answer: \(answerText)")
        if let photoData = selectedPhotoData {
            print("Photo data size: \(photoData.count) bytes")
        }
        
        // Dismiss after sending
        dismiss()
    }
}

#Preview {
    FlowerCareView(
        flower: Flower(name: "Daily Flower", imageName: "Flower", isCurrent: true),
        selectedTheme: .pastelGreen
    )
}

