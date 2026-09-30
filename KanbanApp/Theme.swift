import SwiftUI
import AppKit

/// One set of timings so every animation in the app feels related.
enum Motion {
    /// Content changing in place (view switch, filter, editor appearing).
    static let swap = Animation.easeInOut(duration: 0.2)
    /// Bigger context changes (switching Board/Timeline/Done).
    static let screen = Animation.easeInOut(duration: 0.22)
}

/// Meaning-driven color for status tags — green = fine/done, orange = needs
/// attention soon, red = overdue/act now, purple = informational, gray =
/// inactive.
enum Tag {
    case fine, attention, urgent, info, inactive

    var color: Color {
        switch self {
        case .fine: return .green
        case .attention: return .orange
        case .urgent: return .red
        case .info: return .purple
        case .inactive: return .secondary
        }
    }
}

/// Small status label: colored text on the same color at 15% opacity.
@MainActor
struct TagBadge: View {
    let text: String
    let tag: Tag

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .foregroundStyle(tag.color)
            .background(tag.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
    }
}

/// Capsule filter chip — selected = primary color fill with window-background
/// text, unselected = secondary at 12%.
@MainActor
struct FilterChip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title).font(.callout)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 10).padding(.vertical, 3)
                .foregroundStyle(selected ? Color(nsColor: .windowBackgroundColor) : .primary)
                .background(selected ? Color.primary : Color.secondary.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A card surface — `.background` fill with a hairline `.separator` stroke.
extension View {
    func cardStyle(radius: CGFloat = 10) -> some View {
        background(.background, in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(.separator))
    }

    /// Same shape, tinted red for the Deadline Missed column — kept subtle
    /// (low opacity throughout) so it reads as flagged, not alarming.
    func missedCardStyle(radius: CGFloat = 10) -> some View {
        background(Tag.urgent.color.opacity(0.07), in: RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Tag.urgent.color.opacity(0.35)))
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var symbol: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }

    var title: String { rawValue.capitalized }
}

/// Compact System / Light / Dark switch, segmented with SF Symbols.
@MainActor
struct AppearanceToggle: View {
    @AppStorage("appearanceMode") private var appearanceRaw = AppearanceMode.system.rawValue

    var body: some View {
        Picker("Appearance", selection: $appearanceRaw) {
            ForEach(AppearanceMode.allCases) { mode in
                Image(systemName: mode.symbol)
                    .help(mode.title)
                    .accessibilityLabel(mode.title)
                    .tag(mode.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 76)
    }
}

extension TaskPriority {
    var tag: Tag {
        switch self {
        case .low: return .fine
        case .medium: return .attention
        case .high: return .urgent
        }
    }
}

/// Fades a screen in when it appears — opacity only (no offset/size
/// animation) so it doesn't fight the panel's own AppKit-driven resizing.
struct FadeIn: ViewModifier {
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .onAppear { withAnimation(Motion.screen) { shown = true } }
    }
}
