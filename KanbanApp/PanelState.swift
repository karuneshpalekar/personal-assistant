import SwiftUI

final class PanelState: ObservableObject {
    private static let isCollapsedKey = "panelIsCollapsed"

    @Published var isCollapsed: Bool {
        didSet {
            UserDefaults.standard.set(isCollapsed, forKey: Self.isCollapsedKey)
        }
    }

    /// Not persisted — the panel should always show on next launch
    /// regardless of whether it was hidden when the app last quit.
    @Published var isHidden: Bool = false

    init() {
        isCollapsed = UserDefaults.standard.bool(forKey: Self.isCollapsedKey)
    }
}
