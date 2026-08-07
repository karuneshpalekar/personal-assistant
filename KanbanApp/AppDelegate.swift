import SwiftUI
import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel?
    let editorState = EditorState()
    let taskStore = TaskStore()
    let panelState = PanelState()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = ContentView()
            .environmentObject(editorState)
            .environmentObject(taskStore)
            .environmentObject(panelState)

        let panel = FloatingPanel(contentView: content)
        if let screen = NSScreen.main {
            let origin = NSPoint(
                x: screen.visibleFrame.maxX - panel.frame.width - 24,
                y: screen.visibleFrame.maxY - panel.frame.height - 24
            )
            panel.setFrameOrigin(origin)
        }
        panel.orderFrontRegardless()
        self.panel = panel

        panelState.$isCollapsed
            .removeDuplicates()
            .sink { [weak panel] collapsed in
                panel?.setCollapsed(collapsed)
            }
            .store(in: &cancellables)
    }

    func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.orderFrontRegardless()
        }
    }
}
