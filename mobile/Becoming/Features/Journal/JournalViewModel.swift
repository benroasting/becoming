//
//  JournalViewModel.swift
//  Becoming
//

import Foundation
import Observation

@Observable
final class JournalViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    private(set) var entries: [JournalEntry] = []
    private(set) var values: [Value] = []
    private(set) var state: LoadState = .idle
    var actionError: String?

    private let journalService: any JournalServicing
    private let valueService: any ValueServicing

    init(journalService: any JournalServicing, valueService: any ValueServicing) {
        self.journalService = journalService
        self.valueService = valueService
    }

    func value(id: String) -> Value? {
        values.first { $0.id == id }
    }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            async let e = journalService.journalEntries()
            async let v = valueService.values()
            let (fetchedEntries, fetchedValues) = try await (e, v)
            entries = fetchedEntries.sorted { $0.createdAt > $1.createdAt }
            values = fetchedValues
            state = .loaded
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func create(_ request: JournalEntryRequest) async -> Bool {
        await perform {
            let created = try await self.journalService.createJournalEntry(request)
            self.entries.insert(created, at: 0)
        }
    }

    func update(_ entry: JournalEntry, _ request: JournalEntryRequest) async -> Bool {
        await perform {
            let updated = try await self.journalService.updateJournalEntry(id: entry.id, request)
            if let i = self.entries.firstIndex(where: { $0.id == entry.id }) {
                self.entries[i] = updated
            }
        }
    }

    func delete(_ entry: JournalEntry) async {
        _ = await perform {
            try await self.journalService.deleteJournalEntry(id: entry.id)
            self.entries.removeAll { $0.id == entry.id }
        }
    }

    private func perform(_ work: () async throws -> Void) async -> Bool {
        do {
            try await work()
            return true
        } catch is CancellationError {
            return false
        } catch {
            actionError = error.localizedDescription
            return false
        }
    }
}
