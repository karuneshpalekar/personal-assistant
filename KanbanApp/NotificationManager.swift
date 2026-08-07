import Foundation
import UserNotifications

enum NotificationAction {
    static let snooze = "SNOOZE_1H"
    static let markDone = "MARK_DONE"
    static let deadlineCategory = "DEADLINE_ALERT"
    static let taskIdKey = "taskId"
}

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        registerCategories()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
    }

    private func registerCategories() {
        let snooze = UNNotificationAction(
            identifier: NotificationAction.snooze,
            title: "Snooze 1 Hour",
            options: []
        )
        let markDone = UNNotificationAction(
            identifier: NotificationAction.markDone,
            title: "Mark Done",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: NotificationAction.deadlineCategory,
            actions: [snooze, markDone],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Daily "check your tasks" reminder

    private let lastReminderDateKey = "lastDailyReminderDate"

    /// Sends "check your tasks" once per calendar day — call this at launch
    /// and whenever the Mac wakes from sleep; it no-ops if already sent today.
    func maybeSendDailyReminder() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = UserDefaults.standard.object(forKey: lastReminderDateKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }
        UserDefaults.standard.set(today, forKey: lastReminderDateKey)

        let content = UNMutableNotificationContent()
        content.title = "Kanban Timeline"
        content.body = "Check your tasks for today"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-check-\(today.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    // MARK: - Deadline alerts (24h before due date)

    private func deadlineIdentifier(for taskId: UUID) -> String {
        "deadline-\(taskId.uuidString)"
    }

    /// Reschedules the 24h-before-deadline alert for a task. Call whenever
    /// a task is created/edited/moved so the alert always reflects the
    /// current due date and status.
    func scheduleDeadlineAlert(for task: TaskItem) {
        cancelDeadlineAlert(for: task)
        guard task.status != .done, let due = task.dueDate else { return }

        let alertDate = due.addingTimeInterval(-24 * 60 * 60)
        guard alertDate > Date() else { return }

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        addDeadlineRequest(taskId: task.id, title: "Due tomorrow", body: task.title, trigger: trigger)
    }

    func cancelDeadlineAlert(for task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [deadlineIdentifier(for: task.id)])
    }

    /// Re-fires the same deadline alert one hour from now, in response to
    /// the notification's "Snooze 1 Hour" action.
    func snoozeDeadlineAlert(taskId: UUID, taskTitle: String) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60, repeats: false)
        addDeadlineRequest(taskId: taskId, title: "Due soon (snoozed)", body: taskTitle, trigger: trigger)
    }

    private func addDeadlineRequest(taskId: UUID, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = NotificationAction.deadlineCategory
        content.userInfo = [NotificationAction.taskIdKey: taskId.uuidString]

        let request = UNNotificationRequest(identifier: deadlineIdentifier(for: taskId), content: content, trigger: trigger)
        center.add(request)
    }
}
