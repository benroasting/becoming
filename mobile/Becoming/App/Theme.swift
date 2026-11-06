//
//  Theme.swift
//  Becoming
//
//  The app's visual identity: greyscale surfaces, copper accent, serif headings. Colors adapt to light/dark automatically.
//

import SwiftUI
import UIKit

enum Theme {
    static let background = Color(light: 0xF2F2F2, dark: 0x121212)
    static let card       = Color(light: 0xFFFFFF, dark: 0x1E1E1E)
    static let accent     = Color(light: 0xA8622A, dark: 0xD9915A)

    // Journal impact: growth takes the accent; setback/neutral stay grey and the
    // arrow icon carries the meaning.
    static let growth  = accent
    static let neutral = Color(light: 0x9A9A9A, dark: 0x8A8A8A)
    static let setback = Color(light: 0x5C5C5C, dark: 0xB0B0B0)

    /// Serif face used for titles and headings.
    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    /// Applies navigation/tab bar appearance. Call once at launch.
    static func applyAppearance() {
        func serifFont(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            let base = UIFont.systemFont(ofSize: size, weight: weight)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.backgroundColor = UIColor(background)
        nav.largeTitleTextAttributes = [.font: serifFont(34, .bold)]
        nav.titleTextAttributes = [.font: serifFont(17, .semibold)]

        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.largeTitleTextAttributes = nav.largeTitleTextAttributes
        scrollEdge.titleTextAttributes = nav.titleTextAttributes

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(card)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension View {
    /// Warm background behind a screen's content.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Hides the default grouped-list grey so the warm background shows through.
    func themedScroll() -> some View {
        scrollContentBackground(.hidden)
    }
}
