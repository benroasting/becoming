//
//  ValuesListView.swift
//  Becoming
//

import SwiftUI

struct ValuesListView: View {
    @Environment(\.valueService) private var service
    @Environment(\.journalService) private var journalService
    @Environment(\.habitService) private var habitService
    @Environment(\.checkInService) private var checkInService
    @State private var viewModel: ValuesViewModel?
    @State private var showingNew = false
    @State private var editing: Value?
    @State private var pendingAbandon: Value?

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
            .navigationDestination(for: Value.self) { value in
                ValueDetailView(
                    value: value,
                    journalService: journalService,
                    habitService: habitService,
                    checkInService: checkInService
                )
            }
            .navigationTitle("Values")
            .toolbar {
                Button("Add", systemImage: "plus") { showingNew = true }
                    .disabled(viewModel == nil)
            }
        }
        .sheet(isPresented: $showingNew) {
            if let viewModel { ValueFormView(viewModel: viewModel) }
        }
        .sheet(item: $editing) { value in
            if let viewModel { ValueFormView(viewModel: viewModel, editing: value) }
        }
        .confirmationDialog(
            "Abandon this value?",
            isPresented: Binding(get: { pendingAbandon != nil },
                                 set: { if !$0 { pendingAbandon = nil } }),
            titleVisibility: .visible,
            presenting: pendingAbandon
        ) { value in
            Button("Abandon \"\(value.title)\"", role: .destructive) {
                Task { await viewModel?.abandon(value) }
            }
        } message: { _ in
            Text("This is permanent — abandoned values can't be reactivated.")
        }
        .task {
            if viewModel == nil { viewModel = ValuesViewModel(service: service) }
            await viewModel?.load()
        }
    }

    @ViewBuilder
    private func content(_ vm: ValuesViewModel) -> some View {
        switch vm.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't load values", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await vm.load() } }
            }
        case .loaded:
            list(vm)
        }
    }

    @ViewBuilder
    private func list(_ vm: ValuesViewModel) -> some View {
        if vm.values.isEmpty {
            ContentUnavailableView(
                "No values yet",
                systemImage: "heart.text.square",
                description: Text("Start with who you want to become.")
            )
        } else {
            List {
                Section {
                    ForEach(vm.activeValues) { value in
                        NavigationLink(value: value) { row(value) }
                            .swipeActions {
                                Button("Abandon", role: .destructive) { pendingAbandon = value }
                                Button("Edit") { editing = value }.tint(Theme.neutral)
                            }
                    }
                }
                if !vm.abandonedValues.isEmpty {
                    Section("Abandoned") {
                        ForEach(vm.abandonedValues) { value in
                            NavigationLink(value: value) { row(value) }
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .themedScroll()
            .refreshable { await vm.load() }
        }
    }

    private func row(_ value: Value) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value.title).font(Theme.serif(.headline))
            if !value.description.isEmpty {
                Text(value.description).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Theme.card)
    }
}
