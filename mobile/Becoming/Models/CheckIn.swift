//
//  CheckIn.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

nonisolated struct CheckIn: Codable {
    let id: String
    let habitID: String
    let notes: String
    let completedAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, notes
        case habitID = "habit_id"
        case completedAt = "completed_at"
        case createdAt = "created_at"
    }
}
