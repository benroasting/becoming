//
//  APIClient+CheckIns.swift
//  Becoming
//
//  Created by Ben Young on 8/31/26.
//

import Foundation

nonisolated struct CheckInRequest: Encodable {
    let notes: String
    let completedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case notes
        case completedAt = "completed_at"
    }
}

protocol CheckInServicing {
    func checkIns(habitID: String) async throws -> [CheckIn]
    func createCheckIn(habitID: String, _ request: CheckInRequest) async throws -> CheckIn
}

extension APIClient: CheckInServicing {
    func checkIns(habitID: String) async throws -> [CheckIn] {
        try await get("/habits/\(habitID)/check-ins")
    }
    func createCheckIn(habitID: String, _ request: CheckInRequest) async throws -> CheckIn {
        try await post("/habits/\(habitID)/check-ins", body: request)
    }
}
