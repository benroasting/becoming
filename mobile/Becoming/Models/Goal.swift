//
//  Goal.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

enum GoalStatus: String, Codable, CaseIterable, Identifiable {
    case active, completed, abandoned, inactive

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

nonisolated struct Goal: Codable, Identifiable, Hashable {
    let id: String
    let valueIDs: [String]
    let habitIDs: [String]
    let title: String
    let description: String
    let status: GoalStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case valueIDs = "value_ids"
        case habitIDs = "habit_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
