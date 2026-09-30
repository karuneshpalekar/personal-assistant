#if DEBUG
import AppKit
import SwiftUI

/// Walks Personal Assistant through Board/Timeline/Done and the task
/// editor, in light and dark mode, so a restyle can be checked without
/// clicking through it by hand.
///
///   PA_SHOTS=/tmp/shots /Applications/PersonalAssistant.app/Contents/MacOS/PersonalAssistant
///
/// Captures the panel's own NSWindow (an app may image its own windows
/// without screen-recording permission) — the task editor is drawn inside
/// that same window as an overlay, not a real NSWindow sheet, so there's
/// no separate sheet-compositing step.
@MainActor
enum ScreenshotTour {
    static func run(store: TaskStore, panelState: PanelState, editor: EditorState, panel: FloatingPanel, to dir: URL) async {
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        panel.orderFrontRegardless()
        await pause(1.0)

        for mode in [AppearanceMode.light, .dark] {
            UserDefaults.standard.set(mode.rawValue, forKey: "appearanceMode")
            editor.target = nil

            for boardMode in BoardMode.allCases {
                panelState.mode = boardMode
                await pause(0.6)
                save(panel, "\(boardMode.rawValue.lowercased())-\(mode.rawValue)", dir)
            }

            panelState.mode = .kanban
            editor.target = .new
            await pause(0.6)
            save(panel, "task-editor-\(mode.rawValue)", dir)
            editor.target = nil
            await pause(0.3)
        }

        UserDefaults.standard.set(AppearanceMode.system.rawValue, forKey: "appearanceMode")
        print("SHOTS OK")
        exit(0)
    }

    private static func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .milliseconds(Int(seconds * 1000)))
    }

    private static func image(of window: NSWindow) -> CGImage? {
        CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber),
                                [.boundsIgnoreFraming, .bestResolution])
    }

    private static func save(_ window: NSWindow, _ name: String, _ dir: URL) {
        window.displayIfNeeded()
        guard let img = image(of: window) else { print("shots: failed \(name)"); return }
        let rep = NSBitmapImageRep(cgImage: img)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: dir.appendingPathComponent("\(name).png"))
        print("shots: \(name).png \(img.width)x\(img.height)")
    }
}
#endif
