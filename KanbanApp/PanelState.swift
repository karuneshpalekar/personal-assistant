import SwiftUI

final class PanelState: ObservableObject {
    /// Not persisted — the panel should always show on next launch
    /// regardless of whether it was hidden when the app last quit.
    @Published var isHidden: Bool = false

    /// Which top-level view is showing. Not persisted, and not just local
    /// view state: living here lets the DEBUG screenshot tour (see
    /// Screenshots.swift) drive the UI from outside ContentView.
    @Published var mode: BoardMode = .kanban
}
