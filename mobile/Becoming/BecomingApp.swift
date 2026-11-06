//
//  BecomingApp.swift
//  Becoming
//
//  Created by Ben Young on 7/31/26.
//

import SwiftUI

@main
struct BecomingApp: App {
    init() {
        Theme.applyAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Theme.accent)
        }
    }
}
