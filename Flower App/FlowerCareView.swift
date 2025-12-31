//
//  FlowerCareView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import AVFoundation

// Flower Care Screen (S-002) - F-002: Daily Question, F-003: Photo Sending
struct FlowerCareView: View {
    let flower: Flower
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext  // B-004: For saving data
    @Query private var allCareEntries: [DailyCare]
    @Query(sort: [SortDescriptor(\QuestionHistory.dateCompleted, order: .reverse)]) private var historyEntries: [QuestionHistory]
    
    @State private var answerText: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    // Daily question system (F-002) - changes when questions are answered
    // Each user gets a new question after answering (not waiting for partner)
    private var dailyQuestion: String {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get all questions that have been used by this user today (not archived yet)
        let userAnswersToday = allCareEntries.filter { care in
            care.flowerId == flower.id &&
            care.effectiveUserId == currentUserId &&
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            !care.effectiveIsArchived
        }
        
        // Get all questions that have been archived or moved to history
        let archivedQuestions = Set(
            allCareEntries.filter { $0.effectiveIsArchived }.compactMap { $0.questionText } +
            historyEntries.map { $0.questionText }
        )
        
        // Get questions used by this user today (not yet archived)
        let userQuestionsToday = Set(userAnswersToday.compactMap { $0.questionText })
        
        // Find the first question that hasn't been used by this user today and isn't archived
        if let unusedQuestion = dailyQuestions.first(where: { 
            !userQuestionsToday.contains($0) && !archivedQuestions.contains($0)
        }) {
            return unusedQuestion
        }
        
        // If all questions have been used, cycle through them based on count
        let totalUsed = userQuestionsToday.count + archivedQuestions.count
        let questionIndex = totalUsed % dailyQuestions.count
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
    
    // Text color for TextEditor - dark text in dark mode for visibility on light background
    private var textEditorColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.black // Dark text for visibility on light background
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
                                .foregroundColor(textEditorColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(primaryTextColor.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        
                        // Photo Button (F-003: Photo Sending)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add a Photo")
                                .font(.headline)
                                .foregroundColor(primaryTextColor.opacity(0.7))
                            
                            Button(action: {
                                showPhotoActionSheet()
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
            .onChange(of: cameraImage) {
                if let image = cameraImage {
                    // Convert UIImage to Data
                    selectedPhotoData = image.jpegData(compressionQuality: 0.8)
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView(image: $cameraImage)
            }
            .confirmationDialog("Add Photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        handleCameraAction()
                    }
                }
                Button("Choose from Library") {
                    showPhotoPicker = true
                }
                Button("Cancel", role: .cancel) { }
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
    
    @State private var showPhotoOptions = false
    
    // Show photo action sheet using SwiftUI confirmationDialog (F-003: Photo Sending)
    private func showPhotoActionSheet() {
        showPhotoOptions = true
    }
    
    // Handle camera permission and show camera
    private func handleCameraAction() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch authStatus {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        showError = true
                        errorMessage = "Camera access is required to take photos. Please enable it in Settings."
                    }
                }
            }
        case .denied, .restricted:
            showError = true
            errorMessage = "Camera access is required. Please enable it in Settings."
        @unknown default:
            showError = true
            errorMessage = "Unable to access camera."
        }
    }
    
    // Send care function (B-004: Save answers and photos)
    private func sendCare() {
        // Validate answer
        guard !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError = true
            errorMessage = "Please provide an answer to the question."
            return
        }
        
        // Prevent multiple saves
        guard !isSaving else { return }
        isSaving = true
        
        // Save to database (B-004: D-006 and D-007)
        do {
            // Create DailyCare entry
            let care = DailyCare(
                flowerId: flower.id,
                userId: currentUserId,  // Save with current user ID
                date: Calendar.current.startOfDay(for: Date()), // Use start of day for date matching
                answerText: answerText.trimmingCharacters(in: .whitespacesAndNewlines), // D-006
                photoData: selectedPhotoData, // D-007
                isCompleted: true,
                questionText: dailyQuestion  // Save the question that was answered
            )
            
            // Insert and save to SwiftData
            modelContext.insert(care)
            try modelContext.save()
            
            // Health will be replenished in FlowerCareSheetView when both users have answered
            print("Care saved successfully!")
            print("Answer: \(care.answerText)")
            print("Photo: \(care.photoData != nil ? "Yes (\(care.photoData!.count) bytes)" : "No")")
            print("Answer: \(care.answerText)")
            print("Photo: \(care.photoData != nil ? "Yes (\(care.photoData!.count) bytes)" : "No")")
            
            // Don't dismiss - the sheet will automatically update to show FlowerAnswerView
            // This allows the user to see their answer and continue chatting
            // The FlowerCareSheetView will detect the new care entry and switch views
        } catch {
            isSaving = false
            showError = true
            errorMessage = "Failed to save your care. Please try again."
            print("Error saving care: \(error)")
        }
    }
}

#Preview {
    FlowerCareView(
        flower: Flower(name: "Daily Flower", imageName: "Flower", isCurrent: true),
        selectedTheme: .pastelGreen,
        currentUserId: "user1"
    )
}

