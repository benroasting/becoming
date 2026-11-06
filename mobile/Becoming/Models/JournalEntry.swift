//
//  JournalEntry.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

/// How an entry affected a value. Stored on the wire as -1 / 0 / 1.
enum Impact: Int, CaseIterable, Identifiable {
    case setback = -1, neutral = 0, growth = 1

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .setback: "Setback"
        case .neutral: "Neutral"
        case .growth: "Growth"
        }
    }
}

nonisolated struct JournalValueTag: Codable, Hashable {
    let valueID: String
    let impact: Int
    
    enum CodingKeys: String, CodingKey {
        case valueID = "value_id"
        case impact
    }
}

nonisolated struct JournalEntry: Codable, Identifiable, Hashable {
    let id: String
    let content: String
    let valueTags: [JournalValueTag]?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case valueTags = "value_tags"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
