import SwiftUI
import AppKit

/// An NSPanel that behaves like a persistent desktop widget: floats above
/// normal windows and doesn't steal focus from whatever you're doing.
/// Deliberately does NOT use `.canJoinAllSpaces` or `.fullScreenAuxiliary`
/// — it should stay put on whichever desktop Space it was opened on, not
/// follow you to other Spaces or bleed into other apps' full-screen mode.
/// Also deliberately does NOT use isMovableByWindowBackground — that made
/// the whole panel drag around when trying to drag a task card between
/// columns. Repositioning the panel is done via DragHandle, applied only
/// to the toolbar header.
final class FloatingPanel: NSPanel {
    static let expandedSize = NSSize(width: 900, height: 640)
    static let collapsedSize = NSSize(width: 280, height: 72)

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.stationary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        standardWindowButton(.zoomButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true

        self.contentView = NSHostingView(rootView: contentView)
    }

    /// Resizes toward/from a compact pill, keeping the top-right corner
    /// anchored in place so it collapses/expands like a real widget rather
    /// than jumping around the screen.
    func setCollapsed(_ collapsed: Bool) {
        let newSize = collapsed ? Self.collapsedSize : Self.expandedSize
        let topRight = NSPoint(x: frame.maxX, y: frame.maxY)
        let newOrigin = NSPoint(x: topRight.x - newSize.width, y: topRight.y - newSize.height)
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        setFrame(newFrame, display: true, animate: true)
    }
}
