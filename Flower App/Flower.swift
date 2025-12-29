//
//  Flower.swift
//  Flower App
//
//  Created by Abraham Ashvil on 12/28/25.
//

import Foundation
import SwiftData

@Model
final class Flower {
    var id: UUID
    var name: String
    var imageName: String
    var isCurrent: Bool
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, imageName: String, isCurrent: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.isCurrent = isCurrent
        self.createdAt = createdAt
    }
}

