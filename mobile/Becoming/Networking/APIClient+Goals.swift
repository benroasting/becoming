//
//  APIClient+Goals.swift
//  Becoming
//
//  Created by Ben Young on 8/31/26.
//

import Foundation

nonisolated struct GoalCreateRequest: Encodable {
    let title: String
    let description: String
    let valueIDs: [String]
    let habitIDs: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, description
        case valueIDs = "value_ids"
        case habitIDs = "habit_ids"
    }
}

nonisolated struct GoalUpdateRequest: Encodable {
    let title: String
    let description: String
    let status: GoalStatus
    let valueIDs: [String]
    let habitIDs: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, description, status
        case valueIDs = "value_ids"
        case habitIDs = "habit_ids"
    }
}

protocol GoalServicing {
    func goals() async throws -> [Goal]
    func goal(id: String) async throws -> Goal
    func createGoal(_ request: GoalCreateRequest) async throws -> Goal
    func updateGoal(id: String, _ request: GoalUpdateRequest) async throws -> Goal
}

extension APIClient: GoalServicing {
    func goals() async throws -> [Goal] {
        try await get("/goals")
    }

    func goal(id: String) async throws -> Goal {
        try await get("/goals/\(id)")
    }

    func createGoal(_ request: GoalCreateRequest) async throws -> Goal {
        try await post("/goals", body: request)
    }

    func updateGoal(id: String, _ request: GoalUpdateRequest) async throws -> Goal {
        try await put("/goals/\(id)", body: request)
    }
}
