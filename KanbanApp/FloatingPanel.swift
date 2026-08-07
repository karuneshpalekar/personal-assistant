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
final class FloatingPanel: NSPanel, NSWindowDelegate {
    static let expandedSize = NSSize(width: 900, height: 640)
    static let collapsedSize = NSSize(width: 280, height: 72)

    private static let originXKey = "panelOriginX"
    private static let originYKey = "panelOriginY"
    private static let widthKey = "panelWidth"
    private static let heightKey = "panelHeight"

    private(set) var isCollapsedState = false

    /// Frame changes aren't persisted until this is true — set once by
    /// AppDelegate after the panel's initial position/size (restored or
    /// default) has been applied, so that initial setup doesn't overwrite
    /// the saved frame with the placeholder construction frame.
    var frameTrackingEnabled = false

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
        delegate = self

        self.contentView = NSHostingView(rootView: contentView)
    }

    /// Resizes toward/from a compact pill, keeping the top-right corner
    /// anchored in place so it collapses/expands like a real widget rather
    /// than jumping around the screen.
    func setCollapsed(_ collapsed: Bool) {
        isCollapsedState = collapsed
        let newSize = collapsed ? Self.collapsedSize : Self.expandedSize
        let topRight = NSPoint(x: frame.maxX, y: frame.maxY)
        let newOrigin = NSPoint(x: topRight.x - newSize.width, y: topRight.y - newSize.height)
        let newFrame = NSRect(origin: newOrigin, size: newSize)
        setFrame(newFrame, display: true, animate: true)
    }

    func windowDidMove(_ notification: Notification) {
        persistFrameIfNeeded()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrameIfNeeded()
    }

    private func persistFrameIfNeeded() {
        guard frameTrackingEnabled, !isCollapsedState else { return }
        let d = UserDefaults.standard
        d.set(frame.origin.x, forKey: Self.originXKey)
        d.set(frame.origin.y, forKey: Self.originYKey)
        d.set(frame.size.width, forKey: Self.widthKey)
        d.set(frame.size.height, forKey: Self.heightKey)
    }

    /// The last-saved expanded frame, if any and still roughly on-screen.
    static func savedFrame(fittingIn screenFrame: NSRect) -> NSRect? {
        let d = UserDefaults.standard
        guard d.object(forKey: originXKey) != nil else { return nil }
        let width = d.double(forKey: widthKey)
        let height = d.double(forKey: heightKey)
        guard width > 100, height > 100 else { return nil }
        let rect = NSRect(x: d.double(forKey: originXKey), y: d.double(forKey: originYKey), width: width, height: height)
        return screenFrame.intersects(rect) ? rect : nil
    }
}
