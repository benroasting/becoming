//
//  APIClient+Habits.swift
//  Becoming
//
//  Created by Ben Young on 8/31/26.
//

import Foundation

nonisolated struct HabitRequest: Encodable {
    let title: String
    let description: String
    let frequency: Frequency
    let customDays: [String]?
    let reminderTime: TimeOfDay?
    let valueIDs: [String]
    
    enum CodingKeys: String, CodingKey {
        case title, description, frequency
        case customDays = "custom_days"
        case reminderTime = "reminder_time"
        case valueIDs = "value_ids"
    }
}

protocol HabitServicing {
    func habits() async throws -> [Habit]
    func habit(id: String) async throws -> Habit
    func createHabit(_ request: HabitRequest) async throws -> Habit
    func updateHabit(_ request: HabitRequest, id: String) async throws -> Habit
    func archiveHabit(id: String) async throws
}

extension APIClient: HabitServicing {
    func habits() async throws -> [Habit] {
        try await get("/habits")
    }
    
    func habit(id: String) async throws -> Habit {
        try await get("/habits/\(id)")
    }
    
    func createHabit(_ request: HabitRequest) async throws -> Habit {
        try await post("/habits", body: request)
    }
    
    func updateHabit(_ request: HabitRequest, id: String) async throws -> Habit {
        try await put("/habits/\(id)", body: request)
    }
    
    func archiveHabit(id: String) async throws {
        try await post("/habits/\(id)/archive")
    }
}
