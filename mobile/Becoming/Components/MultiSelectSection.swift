//
//  MultiSelectSection.swift
//  Becoming
//

import SwiftUI

/// A Form section of tappable rows with checkmarks for picking several items.
struct MultiSelectSection<Item: Identifiable>: View where Item.ID == String {
    let header: String
    var footer: String?
    var emptyMessage: String?
    let items: [Item]
    let title: (Item) -> String
    @Binding var selection: Set<String>

    var body: some View {
        Section {
            if items.isEmpty, let emptyMessage {
                Text(emptyMessage).foregroundStyle(.secondary)
            }
            ForEach(items) { item in
                Button {
                    if selection.contains(item.id) {
                        selection.remove(item.id)
                    } else {
                        selection.insert(item.id)
                    }
                } label: {
                    HStack {
                        Text(title(item)).foregroundStyle(.primary)
                        Spacer()
                        if selection.contains(item.id) {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
        } header: {
            Text(header)
        } footer: {
            if let footer { Text(footer) }
        }
    }
}
