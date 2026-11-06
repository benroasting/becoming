//
//  GoalsViewModel.swift
//  Becoming
//

import Foundation
import Observation

@Observable
final class GoalsViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    private(set) var goals: [Goal] = []
    private(set) var values: [Value] = []
    private(set) var habits: [Habit] = []
    private(set) var state: LoadState = .idle
    var actionError: String?

    private let goalService: any GoalServicing
    private let valueService: any ValueServicing
    private let habitService: any HabitServicing

    init(goalService: any GoalServicing,
         valueService: any ValueServicing,
         habitService: any HabitServicing) {
        self.goalService = goalService
        self.valueService = valueService
        self.habitService = habitService
    }

    var activeGoals: [Goal] { goals.filter { $0.status == .active } }
    var otherGoals: [Goal] { goals.filter { $0.status != .active } }
    var selectableValues: [Value] { values.filter { $0.status == .active } }
    var selectableHabits: [Habit] { habits.filter(\.isActive) }

    func valueTitles(for goal: Goal) -> [String] {
        goal.valueIDs.compactMap { id in values.first { $0.id == id }?.title }
    }

    func habitTitles(for goal: Goal) -> [String] {
        goal.habitIDs.compactMap { id in habits.first { $0.id == id }?.title }
    }

    func load() async {
        if case .loaded = state {} else { state = .loading }
        do {
            async let g = goalService.goals()
            async let v = valueService.values()
            async let h = habitService.habits()
            (goals, values, habits) = try await (g, v, h)
            state = .loaded
        } catch is CancellationError {
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func create(_ request: GoalCreateRequest) async -> Bool {
        await perform {
            let created = try await self.goalService.createGoal(request)
            self.goals.append(created)
        }
    }

    func update(_ goal: Goal, _ request: GoalUpdateRequest) async -> Bool {
        await perform {
            let updated = try await self.goalService.updateGoal(id: goal.id, request)
            if let i = self.goals.firstIndex(where: { $0.id == goal.id }) {
                self.goals[i] = updated
            }
        }
    }

    /// Status-only change that preserves the goal's title, description and links.
    func setStatus(_ status: GoalStatus, for goal: Goal) async {
        _ = await update(goal, GoalUpdateRequest(
            title: goal.title,
            description: goal.description,
            status: status,
            valueIDs: goal.valueIDs,
            habitIDs: goal.habitIDs
        ))
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
