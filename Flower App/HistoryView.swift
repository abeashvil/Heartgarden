//
//  HistoryView.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/30/25.
//

import SwiftUI
import SwiftData

// History view to display all completed questions
struct HistoryView: View {
    let selectedTheme: AppTheme
    let currentUserId: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\QuestionHistory.dateCompleted, order: .reverse)]) private var historyEntries: [QuestionHistory]
    @Query private var allCareEntries: [DailyCare]
    @Query private var allFlowers: [Flower]
    @Query private var allChatMessages: [ChatMessage]
    
    @State private var selectedHistoryEntry: QuestionHistory?
    @State private var showChatView = false
    @State private var selectedFilter: ChatFilter = .all
    
    enum ChatFilter: String, CaseIterable {
        case unread = "Unread"
        case all = "All"
        case saved = "Saved"
    }
    
    private var primaryTextColor: Color {
        switch selectedTheme {
        case .darkMode:
            return Color.white
        default:
            return Color.primary
        }
    }
    
    var body: some View {
        ZStack {
            // Background with theme color
            selectedTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter buttons at the top
                filterButtons
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                
                if filteredHistoryEntries.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(primaryTextColor.opacity(0.5))
                        Text(emptyStateMessage)
                            .font(.headline)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                        Text(emptyStateSubmessage)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // List of history entries
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredHistoryEntries) { entry in
                                historyEntryCard(entry: entry)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(selectedTheme.backgroundColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Question History")
                    .foregroundColor(primaryTextColor)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .sheet(isPresented: $showChatView) {
            if let entry = selectedHistoryEntry {
                historyChatView(entry: entry)
                    .onAppear {
                        // Mark as viewed when chat opens
                        entry.markAsViewed(by: currentUserId)
                        do {
                            try modelContext.save()
                        } catch {
                            print("Error marking as viewed: \(error)")
                        }
                    }
            }
        }
    }
    
    // Check if entry has unread messages
    private func hasUnreadMessages(entry: QuestionHistory) -> Bool {
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
        
        return !unreadChatMessages.isEmpty || partnerAnsweredAfterView
    }
    
    // Filtered history entries based on selected filter
    private var filteredHistoryEntries: [QuestionHistory] {
        switch selectedFilter {
        case .unread:
            return historyEntries.filter { hasUnreadMessages(entry: $0) }
        case .all:
            return historyEntries
        case .saved:
            return historyEntries.filter { $0.effectiveIsSaved }
        }
    }
    
    // Empty state messages
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .unread:
            return "No unread chats"
        case .all:
            return "No questions answered yet"
        case .saved:
            return "No saved chats"
        }
    }
    
    private var emptyStateSubmessage: String {
        switch selectedFilter {
        case .unread:
            return "All caught up!"
        case .all:
            return "Complete questions together to see them here"
        case .saved:
            return "Tap the star icon to save chats"
        }
    }
    
    // Filter buttons
    private var filterButtons: some View {
        HStack(spacing: 12) {
            ForEach(ChatFilter.allCases, id: \.self) { filter in
                filterButton(for: filter)
            }
        }
    }
    
    // Individual filter button
    @ViewBuilder
    private func filterButton(for filter: ChatFilter) -> some View {
        let isSelected = selectedFilter == filter
        Button(action: {
            withAnimation {
                selectedFilter = filter
            }
        }) {
            Text(filter.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? primaryTextColor : primaryTextColor.opacity(0.6))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Group {
                        if isSelected {
                            Capsule()
                                .fill(selectedTheme == .darkMode ? Color.white.opacity(0.1) : Color.white.opacity(0.4))
                        } else {
                            Capsule()
                                .fill(Color.clear)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? primaryTextColor.opacity(0.3) : primaryTextColor.opacity(0.1), lineWidth: 1)
                )
        }
    }
    
    // History entry card
    @ViewBuilder
    private func historyEntryCard(entry: QuestionHistory) -> some View {
        let flower = allFlowers.first { $0.id == entry.flowerId }
        let user1Care = allCareEntries.first { $0.id == entry.user1CareId }
        let user2Care = allCareEntries.first { $0.id == entry.user2CareId }
        let hasUnread = hasUnreadMessages(entry: entry)
        
        ZStack(alignment: .topTrailing) {
            Button(action: {
                selectedHistoryEntry = entry
                // Mark as viewed when opening
                entry.markAsViewed(by: currentUserId)
                do {
                    try modelContext.save()
                } catch {
                    print("Error marking as viewed: \(error)")
                }
                showChatView = true
            }) {
                VStack(alignment: .leading, spacing: 12) {
                    // Question text
                    Text(entry.questionText)
                        .font(.headline)
                        .foregroundColor(primaryTextColor)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Flower name and date
                    HStack {
                        if let flower = flower {
                            Text(flower.name)
                                .font(.caption)
                                .foregroundColor(primaryTextColor.opacity(0.7))
                        }
                        Spacer()
                        Text(entry.dateCompleted, style: .date)
                            .font(.caption)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                    }
                    
                    // Preview of answers
                    HStack(spacing: 8) {
                        if let user1Care = user1Care {
                            Text("👤 \(user1Care.answerText.prefix(30))...")
                                .font(.caption)
                                .foregroundColor(primaryTextColor.opacity(0.6))
                                .lineLimit(1)
                        }
                        if let user2Care = user2Care {
                            Text("👥 \(user2Care.answerText.prefix(30))...")
                                .font(.caption)
                                .foregroundColor(primaryTextColor.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
                .background(transparentBoxBackground)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Top-right indicators
            HStack(spacing: 8) {
                // Save button (hollow star)
                Button(action: {
                    entry.isSaved = !entry.effectiveIsSaved
                    do {
                        try modelContext.save()
                    } catch {
                        print("Error saving/unsaving chat: \(error)")
                    }
                }) {
                    Image(systemName: entry.effectiveIsSaved ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(entry.effectiveIsSaved ? .yellow : primaryTextColor.opacity(0.6))
                }
                .padding(.top, 8)
                
                // Unread indicator (always reserve space to prevent shifting)
                Circle()
                    .fill(hasUnread ? Color.red : Color.clear)
                    .frame(width: 10, height: 10)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
    }
    
    // Chat view for history entry
    @ViewBuilder
    private func historyChatView(entry: QuestionHistory) -> some View {
        let flower = allFlowers.first { $0.id == entry.flowerId }
        let user1Care = allCareEntries.first { $0.id == entry.user1CareId }
        let user2Care = allCareEntries.first { $0.id == entry.user2CareId }
        
        if let flower = flower,
           let care = (user1Care?.effectiveUserId == currentUserId ? user1Care : user2Care),
           let partnerCare = (user1Care?.effectiveUserId == currentUserId ? user2Care : user1Care) {
            FlowerAnswerView(
                flower: flower,
                care: care,
                partnerCare: partnerCare,
                currentUserId: currentUserId,
                selectedTheme: selectedTheme
            )
        } else {
            Text("Unable to load chat")
                .foregroundColor(primaryTextColor)
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

