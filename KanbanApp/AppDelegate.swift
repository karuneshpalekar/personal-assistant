import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel?
    let editorState = EditorState()
    let taskStore = TaskStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let content = ContentView()
            .environmentObject(editorState)
            .environmentObject(taskStore)

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
