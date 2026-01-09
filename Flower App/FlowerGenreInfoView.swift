//
//  FlowerGenreInfoView.swift
//  Flower App
//
//  Created for displaying flower genre information
//

import SwiftUI

struct FlowerGenreInfoView: View {
    let flower: Flower
    let selectedTheme: AppTheme
    var onDismiss: () -> Void
    
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
    
    private var genre: QuestionGenre {
        let genreString = flower.effectiveQuestionGenre
        return QuestionGenre(rawValue: genreString) ?? .relationship
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Popup card
            VStack(spacing: 0) {
                // Header with X button
                HStack {
                    Spacer()
                    Button(action: {
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(primaryTextColor.opacity(0.7))
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 16)
                .padding(.trailing, 16)
                
                // Content
                VStack(spacing: 16) {
                    // Flower name
                    Text(flower.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(primaryTextColor)
                    
                    // Genre info
                    VStack(spacing: 12) {
                        Text("Question Genre")
                            .font(.headline)
                            .foregroundColor(primaryTextColor.opacity(0.7))
                        
                        Text(genre.rawValue)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(primaryTextColor)
                        
                        Text(genre.description)
                            .font(.subheadline)
                            .foregroundColor(primaryTextColor.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .frame(maxWidth: 280)
            .background(transparentBoxBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

