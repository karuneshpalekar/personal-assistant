import SwiftUI
import AppKit

/// An NSPanel that behaves like a persistent desktop widget: stays
/// available without a Dock icon, doesn't steal focus from whatever
/// you're doing when it's not the active window. Deliberately uses normal
/// window layering (not .floating) — whichever app/window you actually
/// click should come to front, same as any regular window; it shouldn't
/// sit permanently above everything else. Deliberately does NOT use
/// `.canJoinAllSpaces` or `.fullScreenAuxiliary` — it should stay put on
/// whichever desktop Space it was opened on, not follow you to other
/// Spaces or bleed into other apps' full-screen mode. Also deliberately
/// does NOT use isMovableByWindowBackground — that made the whole panel
/// drag around when trying to drag a task card between columns.
/// Repositioning the panel is done via DragHandle, applied only to the
/// toolbar header.
final class FloatingPanel: NSPanel, NSWindowDelegate {
    static let defaultSize = NSSize(width: 900, height: 640)
    private static let minFloor = NSSize(width: 600, height: 400)

    private static let originXKey = "panelOriginX"
    private static let originYKey = "panelOriginY"
    private static let widthKey = "panelWidth"
    private static let heightKey = "panelHeight"

    /// Frame changes aren't persisted until this is true — set once by
    /// AppDelegate after the panel's initial position/size (restored or
    /// default) has been applied, so that initial setup doesn't overwrite
    /// the saved frame with the placeholder construction frame.
    var frameTrackingEnabled = false

    init(contentView: some View) {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = false
        level = .normal
        collectionBehavior = [.stationary]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        // No .miniaturizable in styleMask above, so there's no minimize
        // capability or button at all — nothing further to disable there.
        standardWindowButton(.zoomButton)?.isHidden = true
        delegate = self

        self.contentView = NSHostingView(rootView: contentView)

        // A floor, not a hard pin — the panel is freely resizable by
        // dragging its edges (the frame is persisted across launches), it
        // just can't be dragged smaller than this.
        minSize = Self.minFloor
    }

    func windowDidMove(_ notification: Notification) {
        persistFrameIfNeeded()
    }

    func windowDidResize(_ notification: Notification) {
        persistFrameIfNeeded()
    }

    private func persistFrameIfNeeded() {
        guard frameTrackingEnabled else { return }
        let d = UserDefaults.standard
        d.set(frame.origin.x, forKey: Self.originXKey)
        d.set(frame.origin.y, forKey: Self.originYKey)
        d.set(frame.size.width, forKey: Self.widthKey)
        d.set(frame.size.height, forKey: Self.heightKey)
    }

    /// The last-saved frame, if any and still roughly on-screen.
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
