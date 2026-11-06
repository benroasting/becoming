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

    private let service: any JournalServicing

    init(value: Value, service: any JournalServicing) {
        self.value = value
        self.service = service
    }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            let entries = try await service.journalEntries()
            journey = ValueJourney(value: value, entries: entries)
            state = .loaded
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
