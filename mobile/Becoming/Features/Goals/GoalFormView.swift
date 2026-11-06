//
//  GoalFormView.swift
//  Becoming
//

import SwiftUI

struct GoalFormView: View {
    let viewModel: GoalsViewModel
    /// nil = creating a new goal.
    let editing: Goal?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var status: GoalStatus
    @State private var selectedValueIDs: Set<String>
    @State private var selectedHabitIDs: Set<String>
    @State private var isSaving = false

    init(viewModel: GoalsViewModel, editing: Goal? = nil) {
        self.viewModel = viewModel
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _description = State(initialValue: editing?.description ?? "")
        _status = State(initialValue: editing?.status ?? .active)
        _selectedValueIDs = State(initialValue: Set(editing?.valueIDs ?? []))
        _selectedHabitIDs = State(initialValue: Set(editing?.habitIDs ?? []))
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !selectedValueIDs.isEmpty
            && !selectedHabitIDs.isEmpty
            && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
              Group {
                Section("Goal") {
                    TextField("e.g. Family dinner phone-free for 30 days", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...6)
                }

                if editing != nil {
                    Section("Status") {
                        Picker("Status", selection: $status) {
                            ForEach(GoalStatus.allCases) { Text($0.label).tag($0) }
                        }
                    }
                }

                MultiSelectSection(
                    header: "Which habits get you there?",
                    footer: "Pick at least one.",
                    emptyMessage: "Create a habit first — a goal needs at least one.",
                    items: viewModel.selectableHabits,
                    title: \.title,
                    selection: $selectedHabitIDs
                )

                MultiSelectSection(
                    header: "Which values does this serve?",
                    footer: "Pick at least one.",
                    emptyMessage: "Create a value first.",
                    items: viewModel.selectableValues,
                    title: \.title,
                    selection: $selectedValueIDs
                )
              }
              .listRowBackground(Theme.card)
            }
            .themedScroll()
            .screenBackground()
            .navigationTitle(editing == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .toolbarButtonFont()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .toolbarButtonFont(emphasized: true)
                        .disabled(!canSave)
                }
            }
            .alert("Couldn't save", isPresented: Binding(
                get: { viewModel.actionError != nil },
                set: { if !$0 { viewModel.actionError = nil } }
            )) {
                Button("OK") { viewModel.actionError = nil }
            } message: {
                Text(viewModel.actionError ?? "")
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let t = title.trimmingCharacters(in: .whitespaces)
        // Preserve the list's ordering rather than Set's arbitrary one.
        let valueIDs = viewModel.selectableValues.map(\.id).filter(selectedValueIDs.contains)
        let habitIDs = viewModel.selectableHabits.map(\.id).filter(selectedHabitIDs.contains)

        let ok: Bool
        if let editing {
            ok = await viewModel.update(editing, GoalUpdateRequest(
                title: t, description: description, status: status,
                valueIDs: valueIDs, habitIDs: habitIDs))
        } else {
            ok = await viewModel.create(GoalCreateRequest(
                title: t, description: description,
                valueIDs: valueIDs, habitIDs: habitIDs))
        }
        if ok { dismiss() }
    }
}
