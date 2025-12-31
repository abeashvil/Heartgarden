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

// Question type enum
enum QuestionType {
    case text
    case photo
}

// Question with type
struct Question {
    let text: String
    let type: QuestionType
}

// Flower Care Screen (S-002) - F-002: Daily Question, F-003: Photo Sending
struct FlowerCareView: View {
    let flower: Flower
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext  // B-004: For saving data
    @Query private var allCareEntries: [DailyCare]
    @Query(sort: [SortDescriptor(\QuestionHistory.dateCompleted, order: .reverse)]) private var historyEntries: [QuestionHistory]
    @Query private var coupleLevels: [CoupleLevel]
    
    @State private var answerText: String = ""
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var refreshCounter: Int = 0  // Force view refresh
    @State private var showPhotoOptions = false
    @State private var skippedQuestions: Set<String> = []  // Track skipped questions
    @State private var questionRefreshAnimation: Bool = false  // For refresh animation
    
    // Get couple level with migration handling
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
    
    // Get number of questions asked by current user today (across all flowers)
    // Only count questions where the user was FIRST to answer (initiated the question)
    // Don't count questions where they answered their partner's question
    // IMPORTANT: Count ALL questions (including archived) to get accurate count
    private var questionsAskedByCurrentUser: Int {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Get all questions answered today (including archived ones for accurate counting)
        let allQuestionsToday = allCareEntries.filter { care in
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            care.questionText != nil
        }
        
        // Group by flower and question text to find who asked first
        var questionsInitiatedByUser = 0
        let questionGroups = Dictionary(grouping: allQuestionsToday) { care in
            "\(care.flowerId.uuidString)|\(care.questionText ?? "")"
        }
        
        for (_, careEntries) in questionGroups {
            // Sort by creation time to find who answered first
            let sortedEntries = careEntries.sorted { $0.createdAt < $1.createdAt }
            if let firstEntry = sortedEntries.first,
               firstEntry.effectiveUserId == currentUserId {
                // Current user was first to answer this question (they asked it)
                questionsInitiatedByUser += 1
            }
        }
        
        return questionsInitiatedByUser
    }
    
    // Get number of questions asked by partner today
    // Only count questions where the partner was FIRST to answer (initiated the question)
    // IMPORTANT: Count ALL questions (including archived) to get accurate count
    private var questionsAskedByPartner: Int {
        let today = Calendar.current.startOfDay(for: Date())
        let partnerId = currentUserId == "user1" ? "user2" : "user1"
        
        // Get all questions answered today (including archived ones for accurate counting)
        let allQuestionsToday = allCareEntries.filter { care in
            Calendar.current.isDate(care.date, inSameDayAs: today) &&
            care.questionText != nil
        }
        
        // Group by flower and question text to find who asked first
        var questionsInitiatedByPartner = 0
        let questionGroups = Dictionary(grouping: allQuestionsToday) { care in
            "\(care.flowerId.uuidString)|\(care.questionText ?? "")"
        }
        
        for (_, careEntries) in questionGroups {
            // Sort by creation time to find who answered first
            let sortedEntries = careEntries.sorted { $0.createdAt < $1.createdAt }
            if let firstEntry = sortedEntries.first,
               firstEntry.effectiveUserId == partnerId {
                // Partner was first to answer this question (they asked it)
                questionsInitiatedByPartner += 1
            }
        }
        
        return questionsInitiatedByPartner
    }
    
    // Calculate how many questions current user can still ask
    // Each user gets half of total, with extra going to first come first serve
    private var questionsAvailableForCurrentUser: Int {
        let totalAvailable = coupleLevel.questionsAvailable
        let basePerUser = totalAvailable / 2
        let hasExtra = totalAvailable % 2 == 1
        
        let userAsked = questionsAskedByCurrentUser
        let partnerAsked = questionsAskedByPartner
        
        // If there's an extra question, first user to reach their base limit gets it
        if hasExtra {
            // If current user has used their base and partner hasn't, or if current user is ahead, they can claim the extra
            if userAsked >= basePerUser && partnerAsked < basePerUser {
                return basePerUser + 1 - userAsked // Can claim the extra
            } else if userAsked < basePerUser {
                return basePerUser - userAsked // Still has base questions left
            } else {
                return 0 // Both used their base, extra already claimed
            }
        } else {
            // No extra question, just base per user
            return max(0, basePerUser - userAsked)
        }
    }
    
    // Get the partner's question text that the current user should answer (if any)
    private var partnerQuestionText: String? {
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
        
        // Find the first unanswered partner question (most recent)
        let unansweredPartnerQuestions = partnerQuestions
            .filter { care in
                guard let questionText = care.questionText else { return false }
                return !userAnswers.contains(questionText)
            }
            .sorted { $0.createdAt > $1.createdAt }
        
        return unansweredPartnerQuestions.first?.questionText
    }
    
    // Check if the current question was already asked by the partner (allows answering even if counter is 0)
    // Also checks if partner has asked ANY question on this flower that current user hasn't answered
    private var isPartnerQuestion: Bool {
        return partnerQuestionText != nil
    }
    
    // Get questions remaining for current user
    private var questionsRemaining: Int {
        questionsAvailableForCurrentUser
    }
    
    // Check if current user can ask a new question
    private var canAnswerQuestion: Bool {
        // Always allow answering partner's questions
        if isPartnerQuestion {
            return true
        }
        
        // Check if current user has questions available
        return questionsAvailableForCurrentUser > 0
    }
    
    // Question limit info view
    @ViewBuilder
    private var questionLimitInfo: some View {
        // Force refresh by using refreshCounter and allCareEntries - this ensures the view updates
        let _ = refreshCounter
        let _ = allCareEntries.count // Force refresh when care entries change
        
        // Calculate per-user question status
        let userAsked = questionsAskedByCurrentUser
        let partnerAsked = questionsAskedByPartner
        let totalAvailable = coupleLevel.questionsAvailable
        let basePerUser = totalAvailable / 2
        let hasExtra = totalAvailable % 2 == 1
        
        // Calculate user's total limit (base + extra if they can claim it)
        let userTotalLimit = hasExtra && userAsked >= basePerUser && partnerAsked < basePerUser 
            ? basePerUser + 1 
            : basePerUser
        
        // Calculate partner's total limit
        let partnerTotalLimit = hasExtra && partnerAsked >= basePerUser && userAsked < basePerUser 
            ? basePerUser + 1 
            : basePerUser
        
        let userRemaining = max(0, userTotalLimit - userAsked)
        let partnerRemaining = max(0, partnerTotalLimit - partnerAsked)
        let canAnswer = questionsAvailableForCurrentUser > 0
        
        if !canAnswer {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("You've used all \(userTotalLimit) of your questions for today. Level up to get more!")
                    .font(.caption)
                    .foregroundColor(primaryTextColor.opacity(0.7))
            }
            .padding(.horizontal)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.blue)
                    Text("\(userRemaining) questions remaining for you")
                        .font(.caption)
                        .foregroundColor(primaryTextColor.opacity(0.7))
                }
                
                // Show breakdown (remaining/total format)
                HStack(spacing: 8) {
                    Text("You: \(userRemaining)/\(userTotalLimit)")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.6))
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.4))
                    Text("Partner: \(partnerRemaining)/\(partnerTotalLimit)")
                        .font(.caption2)
                        .foregroundColor(primaryTextColor.opacity(0.6))
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Daily question system (F-002) - changes when questions are answered
    // Each user gets a new question after answering (not waiting for partner)
    // Limited by level
    private var currentQuestion: Question {
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
        
        // Combine used and skipped questions
        let excludedQuestions = userQuestionsToday.union(skippedQuestions)
        
        // Find the first question that hasn't been used by this user today, isn't archived, and isn't skipped
        if let unusedQuestion = dailyQuestions.first(where: { question in
            !excludedQuestions.contains(question.text) && !archivedQuestions.contains(question.text)
        }) {
            return unusedQuestion
        }
        
        // If all questions have been used or skipped, cycle through them based on count
        let totalUsed = excludedQuestions.count + archivedQuestions.count
        let questionIndex = totalUsed % dailyQuestions.count
        return dailyQuestions[questionIndex]
    }
    
    // Convenience property for question text
    private var dailyQuestion: String {
        currentQuestion.text
    }
    
    // Check if current question requires a photo
    private var isPhotoQuestion: Bool {
        currentQuestion.type == .photo
    }
    
    // Questions with types (F-002 requirement)
    private let dailyQuestions: [Question] = [
        Question(text: "What made you smile today?", type: .text),
        Question(text: "What are you grateful for today?", type: .text),
        Question(text: "What's one thing you love about your partner?", type: .text),
        Question(text: "What's a memory that makes you happy?", type: .text),
        Question(text: "What are you looking forward to?", type: .text),
        Question(text: "What made today special?", type: .text),
        Question(text: "What's something you appreciate about your relationship?", type: .text),
        Question(text: "What's a small moment of joy you had today?", type: .text),
        Question(text: "What's something you're proud of?", type: .text),
        Question(text: "What's a goal you're working towards together?", type: .text),
        Question(text: "What's something that made you laugh today?", type: .text),
        Question(text: "What's a tradition you want to start?", type: .text),
        Question(text: "What's your favorite thing to do together?", type: .text),
        Question(text: "What's something new you learned about your partner?", type: .text),
        Question(text: "What's a dream you share?", type: .text),
        Question(text: "What's something that brings you closer?", type: .text),
        Question(text: "What's a challenge you've overcome together?", type: .text),
        Question(text: "What's something you want to try together?", type: .text),
        Question(text: "What's a place you want to visit together?", type: .text),
        Question(text: "What's something that makes your relationship unique?", type: .text),
        Question(text: "What's a habit you want to build together?", type: .text),
        Question(text: "What's something that surprised you today?", type: .text),
        Question(text: "What's a quality you admire in your partner?", type: .text),
        Question(text: "What's a moment you want to remember?", type: .text),
        Question(text: "What's something that made you feel loved today?", type: .text),
        Question(text: "What's a way you want to grow together?", type: .text),
        Question(text: "What's something that inspires you?", type: .text),
        Question(text: "What's a skill you want to learn together?", type: .text),
        // Photo questions
        Question(text: "Share a photo of something that made you happy today", type: .photo),
        Question(text: "Capture a moment you want to remember together", type: .photo),
        Question(text: "Take a photo of something that represents your relationship", type: .photo),
        Question(text: "Share a picture of something you're grateful for", type: .photo),
        Question(text: "Capture something beautiful you saw today", type: .photo),
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
                
                // Show out of questions screen if no questions and no partner questions
                if !isPartnerQuestion && questionsAvailableForCurrentUser == 0 {
                    outOfQuestionsView
                } else {
                    questionFormView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Care for \(flower.name)")
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
            .onChange(of: allCareEntries.count) { oldValue, newValue in
                // Update counter when care entries change
                refreshCounter += 1
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
    
    // Question form view
    @ViewBuilder
    private var questionFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Daily Question (F-002)
                VStack(alignment: .leading, spacing: 12) {
                    Text(dailyQuestion)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                        .opacity(questionRefreshAnimation ? 0 : 1)
                        .offset(y: questionRefreshAnimation ? -20 : 0)
                        .animation(.easeInOut(duration: 0.3), value: questionRefreshAnimation)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 20)
            
                // Text Answer Box - sleek design
                VStack(alignment: .leading, spacing: 8) {
                    TextEditor(text: $answerText)
                        .frame(minHeight: 150)
                        .padding(16)
                        .background(transparentBoxBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(primaryTextColor.opacity(0.1), lineWidth: 1)
                        )
                        .foregroundColor(textEditorColor)
                        .scrollContentBackground(.hidden)
                }
                .padding(.horizontal)
                
                // Photo Button (F-003: Photo Sending) - only for photo questions
                if isPhotoQuestion {
                    VStack(alignment: .leading, spacing: 8) {
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
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(primaryTextColor.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Skip Button
                Button(action: {
                    skipQuestion()
                }) {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundColor(primaryTextColor.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal)
                
                // Send Button
                Button(action: {
                    sendCare()
                }) {
                    Text(isPartnerQuestion ? "Answer Partner's Question" : (canAnswerQuestion ? "Send" : "No Questions Left"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSend && (isPartnerQuestion || canAnswerQuestion) ? Color.green : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(!canSend)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
    }
    
    // Out of questions view
    @ViewBuilder
    private var outOfQuestionsView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue.opacity(0.6))
            
            // Title
            Text("All Out of Questions")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(primaryTextColor)
            
            // Subtitle
            Text("You've used all your questions for today!")
                .font(.body)
                .foregroundColor(primaryTextColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Ways to get more questions
            VStack(alignment: .leading, spacing: 20) {
                Text("Ways to Get More Questions:")
                    .font(.headline)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal)
                
                // Option 1: Level up
                HStack(spacing: 15) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level Up")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)
                        Text("Gain experience by answering questions together")
                            .font(.caption)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                
                // Option 2: Streak achievements
                HStack(spacing: 15) {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Maintain Streaks")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)
                        Text("Keep your streak going to unlock bonus questions")
                            .font(.caption)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                
                // Option 3: In-app purchase (placeholder)
                HStack(spacing: 15) {
                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purchase Questions")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)
                        Text("Buy additional question packs (Coming soon)")
                            .font(.caption)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                            .italic()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(transparentBoxBackground)
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
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
    
    // Check if can send (answer is required, photo is optional for photo questions)
    private var canSend: Bool {
        if isPhotoQuestion {
            return !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPhotoData != nil
        } else {
            return !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    // Skip question function - refresh with new question
    private func skipQuestion() {
        // Mark current question as skipped
        skippedQuestions.insert(currentQuestion.text)
        
        // Clear the form
        answerText = ""
        selectedPhotoData = nil
        selectedPhoto = nil
        
        // Trigger refresh animation
        withAnimation(.easeInOut(duration: 0.3)) {
            questionRefreshAnimation = true
        }
        
        // After animation, reset and show new question
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            refreshCounter += 1
            withAnimation(.easeInOut(duration: 0.3)) {
                questionRefreshAnimation = false
            }
        }
    }
    
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
        // Check if user can answer this question
        // Always allow answering partner's questions, but check limit for new questions
        if !isPartnerQuestion {
            // This is a new question, check if user has questions remaining
            guard questionsAvailableForCurrentUser > 0 else {
                let totalAvailable = coupleLevel.questionsAvailable
                let basePerUser = totalAvailable / 2
                let userAsked = questionsAskedByCurrentUser
                if userAsked >= basePerUser {
                    showError = true
                    errorMessage = "You've used all \(basePerUser) of your questions for today. You can still answer questions your partner asked you! Level up to unlock more questions."
                } else {
                    showError = true
                    errorMessage = "You've used all your questions for today. You can still answer questions your partner asked you! Level up to unlock more questions."
                }
                return
            }
        }
        // If it's a partner's question, always allow (no guard needed)
        
        // Validate answer - for photo questions, allow empty text if photo is provided
        if isPhotoQuestion {
            guard !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPhotoData != nil else {
                showError = true
                errorMessage = "Please provide an answer or a photo."
                return
            }
        } else {
            guard !answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                showError = true
                errorMessage = "Please provide an answer to the question."
                return
            }
        }
        
        // Prevent multiple saves
        guard !isSaving else { return }
        isSaving = true
        
        // Save to database (B-004: D-006 and D-007)
        do {
            // Create DailyCare entry
            // Use partner's actual question text if answering their question, otherwise use current question
            let questionToSave = isPartnerQuestion ? (partnerQuestionText ?? currentQuestion.text) : currentQuestion.text
            
            let care = DailyCare(
                flowerId: flower.id,
                userId: currentUserId,  // Save with current user ID
                date: Calendar.current.startOfDay(for: Date()), // Use start of day for date matching
                answerText: answerText.trimmingCharacters(in: .whitespacesAndNewlines), // D-006
                photoData: selectedPhotoData, // D-007
                isCompleted: true,
                questionText: questionToSave  // Save the actual question that was answered
            )
            
            // Insert and save to SwiftData
            modelContext.insert(care)
            try modelContext.save()
            
            // Force view refresh to update counter immediately
            refreshCounter += 1
            
            // Reset saving state
            isSaving = false
            
            // Health will be replenished in FlowerCareSheetView when both users have answered
            // Calculate remaining after save (per-user system)
            let remainingAfterSave = questionsAvailableForCurrentUser
            
            print("Care saved successfully!")
            print("Answer: \(care.answerText)")
            print("Photo: \(care.photoData != nil ? "Yes (\(care.photoData!.count) bytes)" : "No")")
            print("Questions remaining: \(remainingAfterSave)")
            
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

