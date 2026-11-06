//
//  ValueFormView.swift
//  Becoming
//

import SwiftUI

struct ValueFormView: View {
    let viewModel: ValuesViewModel
    /// nil = creating a new value.
    let editing: Value?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var isSaving = false

    init(viewModel: ValuesViewModel, editing: Value? = nil) {
        self.viewModel = viewModel
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _description = State(initialValue: editing?.description ?? "")
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
              Group {
                Section("Who are you becoming?") {
                    TextField("e.g. A present husband", text: $title)
                }
                Section("What does it look like?") {
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...8)
                }
              }
              .listRowBackground(Theme.card)
            }
            .themedScroll()
            .screenBackground()
            .navigationTitle(editing == nil ? "New Value" : "Edit Value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(!canSave)
                }
            }
            .alert("Couldn't save", isPresented: errorBinding) {
                Button("OK") { viewModel.actionError = nil }
            } message: {
                Text(viewModel.actionError ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { viewModel.actionError != nil },
                set: { if !$0 { viewModel.actionError = nil } })
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let t = title.trimmingCharacters(in: .whitespaces)
        let ok: Bool
        if let editing {
            ok = await viewModel.update(editing, title: t, description: description)
        } else {
            ok = await viewModel.create(title: t, description: description)
        }
        if ok { dismiss() }
    }
}
