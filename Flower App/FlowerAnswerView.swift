//
//  FlowerAnswerView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import SwiftUI
import SwiftData

// View to display answered flower care with chat functionality
struct FlowerAnswerView: View {
    let flower: Flower
    let care: DailyCare
    let partnerCare: DailyCare?
    let currentUserId: String
    let selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var newMessageText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Query private var allChatMessages: [ChatMessage]
    
    // Filter chat messages for this care entry (include messages from both users' care entries)
    private var chatMessages: [ChatMessage] {
        // Get both care IDs (current user and partner)
        var careIds: Set<UUID> = [care.id]
        if let partnerCare = partnerCare {
            careIds.insert(partnerCare.id)
        }
        
        // Filter messages that belong to either care entry
        return allChatMessages.filter { careIds.contains($0.careId) }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    // Check if partner has also answered
    private var partnerHasAnswered: Bool {
        return partnerCare != nil
    }
    
    // Get all messages for this care entry, sorted by date
    private var allMessages: [MessageItem] {
        var messages: [MessageItem] = []
        
        // Add initial answers as messages
        if let partnerCare = partnerCare, partnerCare.createdAt < care.createdAt {
            messages.append(MessageItem(type: .answer, care: partnerCare, isCurrentUser: false))
            messages.append(MessageItem(type: .answer, care: care, isCurrentUser: true))
        } else {
            messages.append(MessageItem(type: .answer, care: care, isCurrentUser: true))
            if let partnerCare = partnerCare {
                messages.append(MessageItem(type: .answer, care: partnerCare, isCurrentUser: false))
            }
        }
        
        // Add chat messages (already filtered and sorted in chatMessages computed property)
        for message in chatMessages {
            messages.append(MessageItem(
                type: .chat,
                chatMessage: message,
                isCurrentUser: message.effectiveUserId == currentUserId
            ))
        }
        
        return messages.sorted { $0.createdAt < $1.createdAt }
    }
    
    // Message item for unified display
    struct MessageItem: Identifiable {
        let id: UUID
        let type: MessageType
        let care: DailyCare?
        let chatMessage: ChatMessage?
        let isCurrentUser: Bool
        let createdAt: Date
        
        enum MessageType {
            case answer
            case chat
        }
        
        init(type: MessageType, care: DailyCare? = nil, chatMessage: ChatMessage? = nil, isCurrentUser: Bool) {
            self.id = UUID()
            self.type = type
            self.care = care
            self.chatMessage = chatMessage
            self.isCurrentUser = isCurrentUser
            self.createdAt = care?.createdAt ?? chatMessage?.createdAt ?? Date()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                selectedTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 24) {
                                // Flower image at top
                                Image(flower.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .padding(.top, 20)
                                
                                // Chat-style message display
                                VStack(spacing: 16) {
                                    // Show all messages (answers + chat)
                                    ForEach(allMessages) { messageItem in
                                        if messageItem.type == .answer, let care = messageItem.care {
                                            messageBubble(care: care, isCurrentUser: messageItem.isCurrentUser)
                                                .id(messageItem.id)
                                        } else if messageItem.type == .chat, let chatMsg = messageItem.chatMessage {
                                            chatMessageBubble(message: chatMsg, isCurrentUser: messageItem.isCurrentUser)
                                                .id(messageItem.id)
                                        }
                                    }
                                    
                                    // Show waiting message if partner hasn't answered
                                    if !partnerHasAnswered {
                                        waitingMessageBubble
                                    }
                                }
                                .padding(.vertical)
                                
                                // Spacer to push content up
                                Spacer()
                                    .frame(height: 20)
                            }
                            .padding(.bottom, 80) // Space for input field
                        }
                        .onAppear {
                            // Scroll to bottom on appear
                            if let lastMessage = allMessages.last {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: allMessages.count) {
                            // Scroll to bottom when new message is added
                            if let lastMessage = allMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Chat input field (only show if both users have answered)
                    if partnerHasAnswered {
                        chatInputField
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Care")
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
    
    // Message bubble view
    @ViewBuilder
    private func messageBubble(care: DailyCare, isCurrentUser: Bool) -> some View {
        if isCurrentUser {
            // Your message - right aligned (sent)
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    // Text message
                    Text(care.answerText)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(18)
                    
                    // Photo if available
                    if let photoData = care.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 300)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    }
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .trailing)
            }
            .padding(.horizontal)
        } else {
            // Partner's message - left aligned (received)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    // Text message
                    Text(care.answerText)
                        .font(.body)
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(transparentBoxBackground)
                        .cornerRadius(18)
                    
                    // Photo if available
                    if let photoData = care.photoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 300)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(primaryTextColor.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
                .frame(maxWidth: .infinity * 0.75, alignment: .leading)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // Waiting message bubble
    private var waitingMessageBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Waiting for partner to answer...")
                    .font(.body)
                    .foregroundColor(primaryTextColor.opacity(0.6))
                    .italic()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(transparentBoxBackground)
                    .cornerRadius(18)
            }
            .frame(maxWidth: .infinity * 0.75, alignment: .leading)
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // Chat message bubble
    @ViewBuilder
    private func chatMessageBubble(message: ChatMessage, isCurrentUser: Bool) -> some View {
        if isCurrentUser {
            // Your chat message - right aligned (sent)
            HStack {
                Spacer()
                Text(message.messageText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(18)
            }
            .padding(.horizontal)
        } else {
            // Partner's chat message - left aligned (received)
            HStack {
                Text(message.messageText)
                    .font(.body)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(transparentBoxBackground)
                    .cornerRadius(18)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
    
    // Chat input field
    private var chatInputField: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $newMessageText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(transparentBoxBackground)
                .cornerRadius(20)
                .foregroundColor(primaryTextColor)
                .lineLimit(1...4)
                .onTapGesture {
                    isTextFieldFocused = true
                }
            
            Button(action: {
                sendChatMessage()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? primaryTextColor.opacity(0.3) : Color.green)
            }
            .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(selectedTheme.backgroundColor)
    }
    
    // Send chat message
    private func sendChatMessage() {
        let messageText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        do {
            let message = ChatMessage(
                careId: care.id,
                userId: currentUserId,
                messageText: messageText
            )
            
            modelContext.insert(message)
            try modelContext.save()
            
            // Clear input
            newMessageText = ""
            
            print("Chat message sent: \(messageText)")
        } catch {
            print("Error sending chat message: \(error)")
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
}

// Query helper to fetch all chat messages (we'll filter by careId in computed property)
extension FlowerAnswerView {
    init(flower: Flower, care: DailyCare, partnerCare: DailyCare?, currentUserId: String, selectedTheme: AppTheme) {
        self.flower = flower
        self.care = care
        self.partnerCare = partnerCare
        self.currentUserId = currentUserId
        self.selectedTheme = selectedTheme
        
        // Query all chat messages - we'll filter by careId in the computed property
        _allChatMessages = Query(sort: \ChatMessage.createdAt)
    }
}

#Preview {
    FlowerAnswerView(
        flower: Flower(name: "Daily Flower", imageName: "Flower", isCurrent: true),
        care: DailyCare(
            flowerId: UUID(),
            userId: "user1",
            answerText: "This is my answer to the daily question."
        ),
        partnerCare: nil,
        currentUserId: "user1",
        selectedTheme: .pastelGreen
    )
}

