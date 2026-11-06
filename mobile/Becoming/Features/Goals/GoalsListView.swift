//
//  GoalsListView.swift
//  Becoming
//

import SwiftUI

struct GoalsListView: View {
    @Environment(\.goalService) private var goalService
    @Environment(\.valueService) private var valueService
    @Environment(\.habitService) private var habitService

    @State private var viewModel: GoalsViewModel?
    @State private var showingNew = false
    @State private var editing: Goal?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel)
                } else {
                    ProgressView()
                }
            }
            .screenBackground()
            .navigationTitle("Goals")
            .toolbar {
                Button("Add", systemImage: "plus") { showingNew = true }
                    .disabled(viewModel == nil)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = GoalsViewModel(
                    goalService: goalService,
                    valueService: valueService,
                    habitService: habitService
                )
            }
            await viewModel?.load()
        }
        .sheet(isPresented: $showingNew) {
            if let viewModel { GoalFormView(viewModel: viewModel) }
        }
        .sheet(item: $editing) { goal in
            if let viewModel { GoalFormView(viewModel: viewModel, editing: goal) }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel?.actionError != nil && !showingNew && editing == nil },
            set: { if !$0 { viewModel?.actionError = nil } }
        )) {
            Button("OK") { viewModel?.actionError = nil }
        } message: {
            Text(viewModel?.actionError ?? "")
        }
    }

    @ViewBuilder
    private func content(_ vm: GoalsViewModel) -> some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load goals", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await vm.load() } }
            }
        case .loaded:
            if vm.goals.isEmpty {
                ContentUnavailableView(
                    "No goals yet",
                    systemImage: "flag",
                    description: Text("A goal is a checkpoint backed by the habits that will get you there.")
                )
            } else {
                List {
                    if !vm.activeGoals.isEmpty {
                        Section {
                            ForEach(vm.activeGoals) { goal in
                                row(goal, vm)
                                    .swipeActions(edge: .leading) {
                                        Button("Complete", systemImage: "checkmark") {
                                            Task { await vm.setStatus(.completed, for: goal) }
                                        }
                                        .tint(Theme.growth)
                                    }
                                    .swipeActions {
                                        Button("Edit") { editing = goal }.tint(Theme.neutral)
                                    }
                            }
                        }
                    }
                    if !vm.otherGoals.isEmpty {
                        Section("Past & paused") {
                            ForEach(vm.otherGoals) { goal in
                                row(goal, vm)
                                    .foregroundStyle(.secondary)
                                    .swipeActions {
                                        Button("Edit") { editing = goal }.tint(Theme.neutral)
                                    }
                            }
                        }
                    }
                }
                .themedScroll()
                .refreshable { await vm.load() }
            }
        }
    }

    private func row(_ goal: Goal, _ vm: GoalsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(goal.title).font(Theme.serif(.headline))
                if goal.status != .active {
                    Text(goal.status.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
            if !goal.description.isEmpty {
                Text(goal.description).font(.subheadline).foregroundStyle(.secondary)
            }
            let habits = vm.habitTitles(for: goal)
            if !habits.isEmpty {
                Label(habits.joined(separator: ", "), systemImage: "repeat")
                    .font(.caption).foregroundStyle(.secondary)
            }
            let values = vm.valueTitles(for: goal)
            if !values.isEmpty {
                Text(values.joined(separator: " · "))
                    .font(.caption).foregroundStyle(.tint)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Theme.card)
    }
}
