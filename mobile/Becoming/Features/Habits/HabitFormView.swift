//
//  HabitFormView.swift
//  Becoming
//

import SwiftUI

struct HabitFormView: View {
    let viewModel: HabitsViewModel
    /// nil = creating a new habit.
    let editing: Habit?

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var frequency: Frequency
    @State private var customDays: Set<String>
    @State private var hasReminder: Bool
    @State private var reminderDate: Date
    @State private var selectedValueIDs: Set<String>
    @State private var isSaving = false

    private static let weekdays = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    init(viewModel: HabitsViewModel, editing: Habit? = nil) {
        self.viewModel = viewModel
        self.editing = editing
        _title = State(initialValue: editing?.title ?? "")
        _description = State(initialValue: editing?.description ?? "")
        _frequency = State(initialValue: editing?.frequency ?? .daily)
        _customDays = State(initialValue: Set(editing?.customDays ?? []))
        _hasReminder = State(initialValue: editing?.reminderTime != nil)
        let t = editing?.reminderTime
        let date = Calendar.current.date(
            bySettingHour: t?.hour ?? 9, minute: t?.minute ?? 0, second: 0, of: .now
        ) ?? .now
        _reminderDate = State(initialValue: date)
        _selectedValueIDs = State(initialValue: Set(editing?.valueIDs ?? []))
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !selectedValueIDs.isEmpty
            && (frequency != .custom || !customDays.isEmpty)
            && !isSaving
    }

    var body: some View {
        NavigationStack {
            Form {
              Group {
                Section("Habit") {
                    TextField("e.g. Put my phone away at dinner", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section("How often?") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if frequency == .custom {
                        ForEach(Self.weekdays, id: \.self) { day in
                            Toggle(day.capitalized, isOn: dayBinding(day))
                        }
                    }
                }

                Section {
                    Toggle("Daily reminder", isOn: $hasReminder)
                    if hasReminder {
                        DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                    }
                }

                MultiSelectSection(
                    header: "Which values does this serve?",
                    footer: "Pick at least one.",
                    emptyMessage: "Create a value first — every habit supports at least one.",
                    items: viewModel.selectableValues,
                    title: \.title,
                    selection: $selectedValueIDs
                )
              }
              .listRowBackground(Theme.card)
            }
            .themedScroll()
            .screenBackground()
            .navigationTitle(editing == nil ? "New Habit" : "Edit Habit")
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

    private func dayBinding(_ day: String) -> Binding<Bool> {
        Binding(
            get: { customDays.contains(day) },
            set: { if $0 { customDays.insert(day) } else { customDays.remove(day) } }
        )
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        let request = HabitRequest(
            title: title.trimmingCharacters(in: .whitespaces),
            description: description,
            frequency: frequency,
            customDays: frequency == .custom
                ? Self.weekdays.filter(customDays.contains)
                : nil,
            reminderTime: hasReminder
                ? TimeOfDay(hour: comps.hour ?? 9, minute: comps.minute ?? 0)
                : nil,
            valueIDs: viewModel.selectableValues.map(\.id).filter(selectedValueIDs.contains)
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
