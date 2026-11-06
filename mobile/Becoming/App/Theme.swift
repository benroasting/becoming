//
//  Theme.swift
//  Becoming
//
//  The app's visual identity: greyscale surfaces, copper accent, Merriweather headings. Colors adapt to light/dark automatically.
//

import CoreText
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

    // MARK: Typography
    //
    // Merriweather (SIL OFL; see Fonts/Merriweather-OFL.txt), shipped unmodified as a
    // variable font and addressed by its named instances. Backup option if we want more
    // character: Fraunces (see PLANNING.md → Design). To swap typefaces, change the
    // names/sizes here and the font file in Fonts/ — every screen goes through `serif`.

    /// Merriweather runs wide with a large x-height, so sizes sit a little under the
    /// system defaults for the same text style.
    private static let sizeScale: CGFloat = 0.92

    private static func baseSize(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }

    private static func serifName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light: "Merriweather-Light"
        case .regular: "Merriweather-Regular"
        case .medium: "Merriweather-Medium"
        case .semibold: "Merriweather-SemiBold"
        case .bold: "Merriweather-Bold"
        case .heavy: "Merriweather-ExtraBold"
        case .black: "Merriweather-Black"
        default: "Merriweather-Regular"
        }
    }

    /// Serif face used for titles, headings, journal text and numbers. Scales with Dynamic Type.
    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .custom(serifName(for: weight), size: baseSize(style) * sizeScale, relativeTo: style)
    }

    /// Registers the bundled font files. Call once at launch, before any text renders.
    static func registerFonts() {
        guard let url = Bundle.main.url(forResource: "Merriweather-Variable", withExtension: "ttf") else {
            assertionFailure("Merriweather font file missing from bundle")
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    /// Applies navigation/tab bar appearance. Call once at launch.
    static func applyAppearance() {
        registerFonts()

        /// A Merriweather UIFont by named instance, falling back to the system serif if the
        /// bundled font failed to load.
        func serifFont(_ size: CGFloat, named name: String) -> UIFont {
            if let font = UIFont(name: name, size: size) { return font }
            let base = UIFont.systemFont(ofSize: size, weight: name.hasSuffix("Bold") ? .bold : .semibold)
            guard let descriptor = base.fontDescriptor.withDesign(.serif) else { return base }
            return UIFont(descriptor: descriptor, size: size)
        }

        // Navigation bar: titles, plus UIKit-drawn bar buttons (e.g. the back button).
        // SwiftUI toolbar buttons ignore this; they use `toolbarButtonFont()` instead.
        let buttonFont = serifFont(15, named: "Merriweather-Regular")
        func styleButtons(of appearance: UINavigationBarAppearance) {
            for button in [appearance.buttonAppearance, appearance.doneButtonAppearance, appearance.backButtonAppearance] {
                button.normal.titleTextAttributes = [.font: buttonFont]
                button.highlighted.titleTextAttributes = [.font: buttonFont]
                button.disabled.titleTextAttributes = [.font: buttonFont]
            }
        }

        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.backgroundColor = UIColor(background)
        nav.largeTitleTextAttributes = [.font: serifFont(30, named: "Merriweather-Bold")]
        nav.titleTextAttributes = [.font: serifFont(16, named: "Merriweather-SemiBold")]
        styleButtons(of: nav)

        let scrollEdge = UINavigationBarAppearance()
        scrollEdge.configureWithTransparentBackground()
        scrollEdge.largeTitleTextAttributes = nav.largeTitleTextAttributes
        scrollEdge.titleTextAttributes = nav.titleTextAttributes
        styleButtons(of: scrollEdge)

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = scrollEdge

        // Tab bar labels.
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(card)
        let tabRegular = serifFont(10, named: "Merriweather-Regular")
        let tabSelected = serifFont(10, named: "Merriweather-SemiBold")
        for layout in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            layout.normal.titleTextAttributes = [.font: tabRegular]
            layout.selected.titleTextAttributes = [.font: tabSelected]
        }
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
    /// Merriweather for a SwiftUI toolbar text button (Save, Cancel). The nav bar appearance
    /// doesn't reach these, so each button opts in.
    func toolbarButtonFont(emphasized: Bool = false) -> some View {
        font(Theme.serif(.callout, weight: emphasized ? .semibold : .regular))
    }

    /// Warm background behind a screen's content.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Hides the default grouped-list grey so the warm background shows through.
    func themedScroll() -> some View {
        scrollContentBackground(.hidden)
    }
}
