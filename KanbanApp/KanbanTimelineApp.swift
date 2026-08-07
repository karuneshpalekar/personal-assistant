import SwiftUI
import AppKit

@main
struct KanbanTimelineApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Kanban Timeline", systemImage: "square.grid.3x2") {
            Button("Show/Hide Board") {
                appDelegate.togglePanel()
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}
