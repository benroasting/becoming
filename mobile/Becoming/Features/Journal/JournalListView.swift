//
//  JournalListView.swift
//  Becoming
//

import SwiftUI

struct JournalListView: View {
    @Environment(\.journalService) private var journalService
    @Environment(\.valueService) private var valueService

    @State private var viewModel: JournalViewModel?
    @State private var showingNew = false
    @State private var editing: JournalEntry?
    @State private var pendingDelete: JournalEntry?

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
            .navigationTitle("Journal")
            .toolbar {
                Button("Write", systemImage: "square.and.pencil") { showingNew = true }
                    .disabled(viewModel == nil)
            }
        }
        .task {
            if viewModel == nil {
                viewModel = JournalViewModel(journalService: journalService, valueService: valueService)
            }
            await viewModel?.load()
        }
        .sheet(isPresented: $showingNew) {
            if let viewModel { JournalFormView(viewModel: viewModel) }
        }
        .sheet(item: $editing) { entry in
            if let viewModel { JournalFormView(viewModel: viewModel, editing: entry) }
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: Binding(get: { pendingDelete != nil },
                                 set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                Task { await viewModel?.delete(entry) }
            }
        } message: { _ in
            Text("This can't be undone.")
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
    private func content(_ vm: JournalViewModel) -> some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load your journal", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await vm.load() } }
            }
        case .loaded:
            if vm.entries.isEmpty {
                ContentUnavailableView(
                    "Nothing written yet",
                    systemImage: "book",
                    description: Text("Capture a moment, and mark how it moved you toward who you want to be.")
                )
            } else {
                List(vm.entries) { entry in
                    row(entry, vm)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = entry }
                        .swipeActions {
                            Button("Delete", role: .destructive) { pendingDelete = entry }
                        }
                }
                .themedScroll()
                .refreshable { await vm.load() }
            }
        }
    }

    private func row(_ entry: JournalEntry, _ vm: JournalViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened).uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(.secondary)

            Text(entry.content)
                .font(Theme.serif(.body, weight: .regular))
                .lineLimit(6)

            let tags = entry.valueTags ?? []
            if !tags.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(tags, id: \.self) { tag in
                        if let impact = Impact(rawValue: tag.impact),
                           let value = vm.value(id: tag.valueID) {
                            Label(value.title, systemImage: impact.symbol)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(impact.color)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
        .listRowBackground(Theme.card)
    }
}
