//
//  ValuesViewModel.swift
//  Becoming
//

import Foundation
import Observation

@Observable
final class ValuesViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    private(set) var values: [Value] = []
    private(set) var state: LoadState = .idle
    var actionError: String?

    private let service: any ValueServicing

    init(service: any ValueServicing) {
        self.service = service
    }

    var activeValues: [Value] { values.filter { $0.status == .active } }
    var abandonedValues: [Value] { values.filter { $0.status == .abandoned } }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            values = try await service.values()
            state = .loaded
        } catch is CancellationError {
            // View went away; leave state as-is.
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Returns true on success so the caller can dismiss a form.
    func create(title: String, description: String) async -> Bool {
        await perform {
            let created = try await self.service.createValue(ValueRequest(title: title, description: description))
            self.values.append(created)
        }
    }

    func update(_ value: Value, title: String, description: String) async -> Bool {
        await perform {
            let updated = try await self.service.updateValue(id: value.id, ValueRequest(title: title, description: description))
            if let i = self.values.firstIndex(where: { $0.id == value.id }) {
                self.values[i] = updated
            }
        }
    }

    func abandon(_ value: Value) async {
        _ = await perform {
            try await self.service.abandonValue(id: value.id)
            // Abandon returns no body; reload to pick up the new status.
            self.values = try await self.service.values()
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
