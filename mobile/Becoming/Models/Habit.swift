//
//  Habit.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

enum Frequency: String, Codable, CaseIterable, Identifiable {
    case hourly, daily, weekly, custom

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

nonisolated struct TimeOfDay: Codable, Hashable {
    let hour: Int
    let minute: Int
}

nonisolated struct Habit: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let frequency: Frequency
    let customDays: [String]?
    let reminderTime: TimeOfDay?
    let isActive: Bool
    let valueIDs: [String]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, frequency
        case customDays = "custom_days"
        case reminderTime = "reminder_time"
        case isActive = "is_active"
        case valueIDs = "value_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
