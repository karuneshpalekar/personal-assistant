import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error {
                print("Notification authorization error: \(error)")
            }
        }
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

    private func deadlineIdentifier(for task: TaskItem) -> String {
        "deadline-\(task.id.uuidString)"
    }

    /// Reschedules the 24h-before-deadline alert for a task. Call whenever
    /// a task is created/edited/moved so the alert always reflects the
    /// current due date and status.
    func scheduleDeadlineAlert(for task: TaskItem) {
        cancelDeadlineAlert(for: task)
        guard task.status != .done, let due = task.dueDate else { return }

        let alertDate = due.addingTimeInterval(-24 * 60 * 60)
        guard alertDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Due tomorrow"
        content.body = task.title
        content.sound = .default

        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: deadlineIdentifier(for: task), content: content, trigger: trigger)
        center.add(request)
    }

    func cancelDeadlineAlert(for task: TaskItem) {
        center.removePendingNotificationRequests(withIdentifiers: [deadlineIdentifier(for: task)])
    }
}
