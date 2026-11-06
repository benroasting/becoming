//
//  HabitsListView.swift
//  Becoming
//

import SwiftUI

struct HabitsListView: View {
    @Environment(\.habitService) private var habitService
    @Environment(\.valueService) private var valueService
    @Environment(\.checkInService) private var checkInService

    @State private var viewModel: HabitsViewModel?
    @State private var showingNew = false
    @State private var editing: Habit?
    @State private var pendingArchive: Habit?

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
            .navigationTitle("Habits")
            .toolbar {
                Button("Add", systemImage: "plus") { showingNew = true }
                    .disabled(viewModel == nil)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = HabitsViewModel(
                    habitService: habitService,
                    valueService: valueService,
                    checkInService: checkInService
                )
            }
            await viewModel?.load()
        }
        .sheet(isPresented: $showingNew) {
            if let viewModel { HabitFormView(viewModel: viewModel) }
        }
        .sheet(item: $editing) { habit in
            if let viewModel { HabitFormView(viewModel: viewModel, editing: habit) }
        }
        .confirmationDialog(
            "Archive this habit?",
            isPresented: Binding(get: { pendingArchive != nil },
                                 set: { if !$0 { pendingArchive = nil } }),
            titleVisibility: .visible,
            presenting: pendingArchive
        ) { habit in
            Button("Archive \"\(habit.title)\"", role: .destructive) {
                Task { await viewModel?.archive(habit) }
            }
        } message: { _ in
            Text("It will be hidden, but its check-in history is kept.")
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
    private func content(_ vm: HabitsViewModel) -> some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load habits", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await vm.load() } }
            }
        case .loaded:
            if vm.activeHabits.isEmpty {
                ContentUnavailableView(
                    "No habits yet",
                    systemImage: "repeat",
                    description: Text("Add a small, repeatable action that serves one of your values.")
                )
            } else {
                List(vm.activeHabits) { habit in
                    row(habit, vm)
                        .swipeActions {
                            Button("Archive", role: .destructive) { pendingArchive = habit }
                            Button("Edit") { editing = habit }.tint(.blue)
                        }
                }
                .themedScroll()
                .refreshable { await vm.load() }
                .sensoryFeedback(.success, trigger: vm.recentCheckInHabitID)
            }
        }
    }

    private func row(_ habit: Habit, _ vm: HabitsViewModel) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title).font(Theme.serif(.headline))
                Text(frequencyText(habit))
                    .font(.subheadline).foregroundStyle(.secondary)
                let titles = vm.valueTitles(for: habit)
                if !titles.isEmpty {
                    Text(titles.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.tint)
                }
            }
            Spacer()
            Button {
                Task { await vm.checkIn(habit) }
            } label: {
                Image(systemName: vm.recentCheckInHabitID == habit.id
                      ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(vm.recentCheckInHabitID == habit.id ? Theme.growth : .secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Check in")
        }
        .padding(.vertical, 4)
        .listRowBackground(Theme.card)
    }

    private func frequencyText(_ habit: Habit) -> String {
        if habit.frequency == .custom, let days = habit.customDays, !days.isEmpty {
            return days.map(\.capitalized).joined(separator: ", ")
        }
        return habit.frequency.label
    }
}
