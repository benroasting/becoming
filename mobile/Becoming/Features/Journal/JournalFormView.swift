//
//  JournalFormView.swift
//  Becoming
//

import SwiftUI

struct JournalFormView: View {
    let viewModel: JournalViewModel
    /// nil = writing a new entry.
    let editing: JournalEntry?

    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    /// value ID → impact. Absent = not tagged.
    @State private var impacts: [String: Impact]
    @State private var isSaving = false
    @FocusState private var focused: Bool

    init(viewModel: JournalViewModel, editing: JournalEntry? = nil) {
        self.viewModel = viewModel
        self.editing = editing
        _content = State(initialValue: editing?.content ?? "")
        var initial: [String: Impact] = [:]
        for tag in editing?.valueTags ?? [] {
            if let impact = Impact(rawValue: tag.impact) { initial[tag.valueID] = impact }
        }
        _impacts = State(initialValue: initial)
    }

    /// Active values, plus any already tagged on this entry (even if since abandoned),
    /// so editing never silently drops a tag.
    private var taggableValues: [Value] {
        viewModel.values.filter { $0.status == .active || impacts[$0.id] != nil }
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section {
                        TextEditor(text: $content)
                            .font(Theme.serif(.body, weight: .regular))
                            .frame(minHeight: 160)
                            .focused($focused)
                            .scrollContentBackground(.hidden)
                    } header: {
                        Text("What's on your heart?")
                    }

                    if !taggableValues.isEmpty {
                        Section {
                            ForEach(taggableValues) { value in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(value.title).font(Theme.serif(.subheadline))
                                    Picker(value.title, selection: binding(for: value.id)) {
                                        Text("—").tag(Impact?.none)
                                        ForEach(Impact.allCases) { impact in
                                            Text(impact.label).tag(Impact?.some(impact))
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .labelsHidden()
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            Text("How did this move you?")
                        } footer: {
                            Text("Optional. Tag a value to mark growth, a setback, or neither.")
                        }
                    }
                }
                .listRowBackground(Theme.card)
            }
            .themedScroll()
            .screenBackground()
            .navigationTitle(editing == nil ? "New Entry" : "Edit Entry")
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
            .onAppear { if editing == nil { focused = true } }
        }
    }

    private func binding(for valueID: String) -> Binding<Impact?> {
        Binding(
            get: { impacts[valueID] },
            set: { impacts[valueID] = $0 }
        )
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        // Keep tags in the values' display order.
        let tags = viewModel.values.compactMap { value in
            impacts[value.id].map { JournalValueTag(valueID: value.id, impact: $0.rawValue) }
        }
        let request = JournalEntryRequest(
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            valueTags: tags
        )

        let ok: Bool
        if let editing {
            ok = await viewModel.update(editing, request)
        } else {
            ok = await viewModel.create(request)
        }
        if ok { dismiss() }
    }
}
