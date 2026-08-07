import SwiftUI
import AppKit

/// A transparent view that lets you drag the containing window by its
/// background, scoped to wherever this is placed (e.g. just the toolbar
/// header) rather than the whole panel — so it doesn't fight with
/// SwiftUI's card drag-and-drop elsewhere in the window.
struct DragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> DragHandleView {
        DragHandleView()
    }

    func updateNSView(_ nsView: DragHandleView, context: Context) {}
}

final class DragHandleView: NSView {
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }
}
