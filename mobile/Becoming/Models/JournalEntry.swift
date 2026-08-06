//
//  JournalEntry.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

nonisolated struct JournalValueTag: Codable {
    let valueID: String
    let impact: Int
    
    enum CodingKeys: String, CodingKey {
        case valueID = "value_id"
        case impact
    }
}

nonisolated struct JournalEntry: Codable {
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
