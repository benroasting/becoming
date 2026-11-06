//
//  ValueJourneyViewModel.swift
//  Becoming
//

import Foundation
import Observation

@Observable
final class ValueJourneyViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    let value: Value
    private(set) var journey: ValueJourney?
    private(set) var state: LoadState = .idle

    private let journalService: any JournalServicing
    private let habitService: any HabitServicing
    private let checkInService: any CheckInServicing

    init(value: Value,
         journalService: any JournalServicing,
         habitService: any HabitServicing,
         checkInService: any CheckInServicing) {
        self.value = value
        self.journalService = journalService
        self.habitService = habitService
        self.checkInService = checkInService
    }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let entries = try await journalService.journalEntries()
            // Check-ins are a secondary signal: if they fail to load, still show the journey.
            let checkIns = (try? await loadCheckIns()) ?? []
            journey = ValueJourney(value: value, entries: entries, checkIns: checkIns)
            state = .loaded
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Check-ins for every habit that serves this value, archived habits included
    /// (their history still happened).
    private func loadCheckIns() async throws -> [CheckIn] {
        let habitIDs = try await habitService.habits()
            .filter { $0.valueIDs.contains(value.id) }
            .map(\.id)
        let service = checkInService
        return try await withThrowingTaskGroup(of: [CheckIn].self) { group in
            for id in habitIDs {
                group.addTask { try await service.checkIns(habitID: id) }
            }
            var all: [CheckIn] = []
            for try await batch in group { all += batch }
            return all
        }
    }
}
