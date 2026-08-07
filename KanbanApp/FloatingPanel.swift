import SwiftUI
import AppKit

/// An NSPanel that behaves like a persistent desktop widget: floats above
/// normal windows, doesn't steal focus from whatever you're doing, and can
/// be dragged anywhere by its background. Deliberately does NOT use
/// `.canJoinAllSpaces` or `.fullScreenAuxiliary` — it should stay put on
/// whichever desktop Space it was opened on, not follow you to other
/// Spaces or bleed into other apps' full-screen mode.
final class FloatingPanel: NSPanel {
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
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        standardWindowButton(.zoomButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true

        self.contentView = NSHostingView(rootView: contentView)
    }
}
