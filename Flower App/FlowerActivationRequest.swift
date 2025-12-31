//
//  FlowerActivationRequest.swift
//  Flower App
//
//  Created for tracking activation/deactivation requests between partners
//

import Foundation
import SwiftData

@Model
final class FlowerActivationRequest {
    var id: UUID
    var flowerId: UUID
    var requestedBy: String  // user1 or user2
    var requestType: String  // "activate" or "deactivate"
    var status: String  // "pending", "approved", "declined", "expired"
    var createdAt: Date
    var respondedAt: Date?
    var respondedBy: String?  // user1 or user2 (who approved/declined)
    
    init(
        id: UUID = UUID(),
        flowerId: UUID,
        requestedBy: String,
        requestType: String,
        status: String = "pending",
        createdAt: Date = Date(),
        respondedAt: Date? = nil,
        respondedBy: String? = nil
    ) {
        self.id = id
        self.flowerId = flowerId
        self.requestedBy = requestedBy
        self.requestType = requestType
        self.status = status
        self.createdAt = createdAt
        self.respondedAt = respondedAt
        self.respondedBy = respondedBy
    }
    
    var isPending: Bool {
        return status == "pending"
    }
    
    var isApproved: Bool {
        return status == "approved"
    }
    
    var isDeclined: Bool {
        return status == "declined"
    }
}

