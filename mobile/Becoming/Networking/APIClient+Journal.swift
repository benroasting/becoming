//
//  APIClient+Journal.swift
//  Becoming
//
//  Created by Ben Young on 9/5/26.
//

import Foundation

nonisolated struct JournalEntryRequest: Encodable {
    let content: String
    let valueTags: [JournalValueTag]?
    
    enum CodingKeys: String, CodingKey {
        case content
        case valueTags = "value_tags"
    }
}

protocol JournalServicing {
    func journalEntries() async throws -> [JournalEntry]
    func journalEntry(id: String) async throws -> JournalEntry
    func createJournalEntry(_ request: JournalEntryRequest) async throws -> JournalEntry
    func updateJournalEntry(id: String, _ request: JournalEntryRequest) async throws -> JournalEntry
    func deleteJournalEntry(id: String) async throws
}

extension APIClient: JournalServicing {
    func journalEntries() async throws -> [JournalEntry] {
        try await get("/journal-entries")
    }

    func journalEntry(id: String) async throws -> JournalEntry {
        try await get("/journal-entries/\(id)")
    }

    func createJournalEntry(_ request: JournalEntryRequest) async throws -> JournalEntry {
        try await post("/journal-entries", body: request)
    }

    func updateJournalEntry(id: String, _ request: JournalEntryRequest) async throws -> JournalEntry {
        try await put("/journal-entries/\(id)", body: request)
    }

    func deleteJournalEntry(id: String) async throws {
        try await delete("/journal-entries/\(id)")
    }
}
