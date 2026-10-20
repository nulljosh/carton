import CoreText
import SwiftUI
import UIKit

/// Mirrors brand/tokens.css.
enum Brand {
    static let accent = Color(red: 0x8c / 255, green: 0x5a / 255, blue: 0x2c / 255)  // kraft deep

    /// Registers the bundled Carton Sans faces and puts them on the navigation bar titles. Call once at launch.
    static func registerFonts() {
        for w in ["Regular", "Medium", "Semibold", "Bold"] {
            if let url = Bundle.main.url(forResource: "CartonSans-\(w)", withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
        let nav = UINavigationBar.appearance()
        if let big = UIFont(name: "CartonSans-Bold", size: 34) { nav.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: big)] }
        if let small = UIFont(name: "CartonSans-Semibold", size: 17) { nav.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: small)] }
    }
}

extension Font {
    /// Carton Sans at a system text style's size, scaling with Dynamic Type.
    static func carton(_ style: Font.TextStyle, _ weight: String = "Regular", size: CGFloat? = nil) -> Font {
        let base: CGFloat = size ?? [.largeTitle: 34, .title: 28, .title2: 22, .title3: 20, .headline: 17, .body: 17,
                                     .callout: 16, .subheadline: 15, .footnote: 13, .caption: 12, .caption2: 11][style] ?? 17
        return .custom("CartonSans-\(weight)", size: base, relativeTo: style)
    }
}
