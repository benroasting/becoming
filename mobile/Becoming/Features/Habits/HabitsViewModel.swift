//
//  HabitsViewModel.swift
//  Becoming
//

import Foundation
import Observation

@Observable
final class HabitsViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    private(set) var habits: [Habit] = []
    private(set) var values: [Value] = []
    private(set) var state: LoadState = .idle
    /// Habit that was just checked in; drives a brief confirmation in the row.
    private(set) var recentCheckInHabitID: String?
    var actionError: String?

    private let habitService: any HabitServicing
    private let valueService: any ValueServicing
    private let checkInService: any CheckInServicing

    init(habitService: any HabitServicing,
         valueService: any ValueServicing,
         checkInService: any CheckInServicing) {
        self.habitService = habitService
        self.valueService = valueService
        self.checkInService = checkInService
    }

    var activeHabits: [Habit] { habits.filter(\.isActive) }
    var selectableValues: [Value] { values.filter { $0.status == .active } }

    func valueTitles(for habit: Habit) -> [String] {
        habit.valueIDs.compactMap { id in values.first { $0.id == id }?.title }
    }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            async let fetchedHabits = habitService.habits()
            async let fetchedValues = valueService.values()
            (habits, values) = try await (fetchedHabits, fetchedValues)
            state = .loaded
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func create(_ request: HabitRequest) async -> Bool {
        await perform {
            let created = try await self.habitService.createHabit(request)
            self.habits.append(created)
        }
    }

    func update(_ habit: Habit, _ request: HabitRequest) async -> Bool {
        await perform {
            let updated = try await self.habitService.updateHabit(request, id: habit.id)
            if let i = self.habits.firstIndex(where: { $0.id == habit.id }) {
                self.habits[i] = updated
            }
        }
    }

    func archive(_ habit: Habit) async {
        _ = await perform {
            try await self.habitService.archiveHabit(id: habit.id)
            self.habits.removeAll { $0.id == habit.id }
        }
    }

    func checkIn(_ habit: Habit) async {
        let ok = await perform {
            _ = try await self.checkInService.createCheckIn(
                habitID: habit.id,
                CheckInRequest(notes: "", completedAt: nil)
            )
        }
        guard ok else { return }
        recentCheckInHabitID = habit.id
        try? await Task.sleep(for: .seconds(2))
        if recentCheckInHabitID == habit.id { recentCheckInHabitID = nil }
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
