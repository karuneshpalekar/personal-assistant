import SwiftUI
import AppKit

@main
struct PersonalAssistantApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Personal Assistant", systemImage: "square.grid.3x2") {
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
