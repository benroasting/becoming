//
//  ContentView.swift
//  Becoming
//
//  Created by Ben Young on 7/31/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Values", systemImage: "heart.text.square") {
                ValuesListView()
            }
            Tab("Habits", systemImage: "repeat") {
                HabitsListView()
            }
            Tab("Goals", systemImage: "flag") {
                GoalsListView()
            }
            Tab("Journal", systemImage: "book") {
                JournalListView()
            }
        }
    }
}

#Preview {
    ContentView()
}
