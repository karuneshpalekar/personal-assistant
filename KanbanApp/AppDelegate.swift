import SwiftUI
import AppKit
import Combine
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    var panel: FloatingPanel?
    let editorState = EditorState()
    let taskStore = TaskStore()
    let panelState = PanelState()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let launchAtLoginEnabled = UserDefaults.standard.object(forKey: "launchAtLoginEnabled") as? Bool ?? true
        LaunchAtLogin.setEnabled(launchAtLoginEnabled)

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
            if let saved = FloatingPanel.savedFrame(fittingIn: screen.visibleFrame) {
                panel.setFrame(saved, display: false)
            } else {
                let origin = NSPoint(
                    x: screen.visibleFrame.maxX - panel.frame.width - 24,
                    y: screen.visibleFrame.maxY - panel.frame.height - 24
                )
                panel.setFrameOrigin(origin)
            }
        }
        if panelState.isCollapsed {
            panel.setCollapsed(true)
        }
        panel.orderFrontRegardless()
        panel.frameTrackingEnabled = true
        self.panel = panel

        panelState.$isCollapsed
            .removeDuplicates()
            .dropFirst()
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard let taskIdString = response.notification.request.content.userInfo[NotificationAction.taskIdKey] as? String,
              let taskId = UUID(uuidString: taskIdString),
              let task = taskStore.tasks.first(where: { $0.id == taskId }) else { return }

        switch response.actionIdentifier {
        case NotificationAction.snooze:
            NotificationManager.shared.snoozeDeadlineAlert(taskId: taskId, taskTitle: task.title)
        case NotificationAction.markDone:
            var updated = task
            updated.status = .done
            taskStore.upsert(updated)
        default:
            break
        }
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
