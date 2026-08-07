import SwiftUI
import AppKit

/// MenuBarExtra panels (`.menuBarExtraStyle(.window)`) receive mouse clicks
/// fine but often never become the key window, so text fields silently
/// refuse keyboard input. Forcing the panel's window to become key whenever
/// this view appears/updates works around it.
struct KeyWindowFinder: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        activate(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        activate(nsView)
    }

    private func activate(_ view: NSView) {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            view.window?.makeKey()
        }
    }
}
