//
//  Impact+Style.swift
//  Becoming
//

import SwiftUI

extension Impact {
    var color: Color {
        switch self {
        case .growth: Theme.growth
        case .neutral: Theme.neutral
        case .setback: Theme.setback
        }
    }

    var symbol: String {
        switch self {
        case .growth: "arrow.up.right"
        case .neutral: "minus"
        case .setback: "arrow.down.right"
        }
    }
}
