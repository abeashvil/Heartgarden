//
//  QuestionGenre.swift
//  Flower App
//
//  Created for question genre categorization
//

import Foundation

enum QuestionGenre: String, CaseIterable {
    case informational = "Informational"
    case romantic = "Romantic"
    case spicy = "Spicy"
    case relationship = "Relationship"
    case photo = "Photo-Based"
    case fun = "Fun"
    case deep = "Deep"
    
    var description: String {
        switch self {
        case .informational:
            return "Questions that help you learn more about each other"
        case .romantic:
            return "Sweet and romantic questions to deepen your connection"
        case .spicy:
            return "Playful and flirty questions to spice things up"
        case .relationship:
            return "Questions about your relationship and partnership"
        case .photo:
            return "Photo-based questions to capture moments together"
        case .fun:
            return "Light-hearted and fun questions to enjoy together"
        case .deep:
            return "Thoughtful questions for meaningful conversations"
        }
    }
}

