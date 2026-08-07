import SwiftUI
import AppKit
import Combine
import UserNotifications
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var panel: FloatingPanel?
    let editorState = EditorState()
    let taskStore = TaskStore()
    let panelState = PanelState()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        try? SMAppService.mainApp.register()

        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.requestAuthorization()
        NotificationManager.shared.maybeSendDailyReminder()
        for task in taskStore.tasks {
            NotificationManager.shared.scheduleDeadlineAlert(for: task)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        let content = ContentView()
            .environmentObject(editorState)
            .environmentObject(taskStore)
            .environmentObject(panelState)

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

        panelState.$isCollapsed
            .removeDuplicates()
            .sink { [weak panel] collapsed in
                panel?.setCollapsed(collapsed)
            }
            .store(in: &cancellables)
    }

    @objc private func handleWake() {
        NotificationManager.shared.maybeSendDailyReminder()
    }

    /// Without this, notifications are silently suppressed while this app
    /// is the frontmost/active app (a real risk here since the floating
    /// panel is often visible and focused).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
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
