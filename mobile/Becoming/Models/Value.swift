//
//  Value.swift
//  Becoming
//
//  Created by Ben Young on 8/6/26.
//

import Foundation

enum ValueStatus: String, Codable {
    case active, abandoned
}

nonisolated struct Value: Codable {
    let id: String
    let title: String
    let description: String
    let status: ValueStatus
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
