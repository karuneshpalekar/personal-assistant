import SwiftUI

final class PanelState: ObservableObject {
    private static let isCollapsedKey = "panelIsCollapsed"

    @Published var isCollapsed: Bool {
        didSet {
            UserDefaults.standard.set(isCollapsed, forKey: Self.isCollapsedKey)
        }
    }

    init() {
        isCollapsed = UserDefaults.standard.bool(forKey: Self.isCollapsedKey)
    }
}
