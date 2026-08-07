import SwiftUI
import AppKit

/// App color palette — distinct, hand-tuned values per appearance rather
/// than generic system grays, so light and dark each look considered
/// rather than one being an inverted afterthought.
enum Theme {
    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }

    static var panelBackground: Color {
        dynamic(
            light: NSColor(red: 0.969, green: 0.973, blue: 0.980, alpha: 1),
            dark: NSColor(red: 0.106, green: 0.110, blue: 0.129, alpha: 1)
        )
    }

    static var columnBackground: Color {
        dynamic(
            light: NSColor(red: 0.933, green: 0.941, blue: 0.953, alpha: 1),
            dark: NSColor(red: 0.161, green: 0.169, blue: 0.192, alpha: 1)
        )
    }

    static var cardBackground: Color {
        dynamic(
            light: NSColor.white,
            dark: NSColor(red: 0.196, green: 0.204, blue: 0.231, alpha: 1)
        )
    }

    static var cardBorder: Color {
        dynamic(
            light: NSColor(red: 0.878, green: 0.890, blue: 0.914, alpha: 1),
            dark: NSColor(red: 0.278, green: 0.290, blue: 0.322, alpha: 1)
        )
    }

    static var accent: Color {
        dynamic(
            light: NSColor(red: 0.345, green: 0.412, blue: 0.953, alpha: 1),
            dark: NSColor(red: 0.541, green: 0.588, blue: 1.0, alpha: 1)
        )
    }

    static var priorityLow: Color {
        dynamic(
            light: NSColor(red: 0.184, green: 0.616, blue: 0.345, alpha: 1),
            dark: NSColor(red: 0.361, green: 0.827, blue: 0.522, alpha: 1)
        )
    }

    static var priorityMedium: Color {
        dynamic(
            light: NSColor(red: 0.898, green: 0.580, blue: 0.043, alpha: 1),
            dark: NSColor(red: 1.0, green: 0.702, blue: 0.322, alpha: 1)
        )
    }

    static var priorityHigh: Color {
        dynamic(
            light: NSColor(red: 0.878, green: 0.267, blue: 0.298, alpha: 1),
            dark: NSColor(red: 1.0, green: 0.443, blue: 0.463, alpha: 1)
        )
    }
}
