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
    /// and whenever the Mac wakes from sleep; it no-ops if already sent
    /// today. Mentions what's actually due/overdue when there's something,
    /// rather than a generic message every time.
    func maybeSendDailyReminder(tasks: [TaskItem]) {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = UserDefaults.standard.object(forKey: lastReminderDateKey) as? Date,
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            return
        }
        UserDefaults.standard.set(today, forKey: lastReminderDateKey)

        let pending = tasks.filter { $0.status != .done && $0.dueDate != nil }
        let dueToday = pending.filter { Calendar.current.isDateInToday($0.dueDate!) }
        let overdue = pending.filter { $0.dueDate! < today }

        let content = UNMutableNotificationContent()
        content.title = "Kanban Timeline"
        content.body = dailyBody(dueToday: dueToday, overdue: overdue)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "daily-check-\(today.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    private func dailyBody(dueToday: [TaskItem], overdue: [TaskItem]) -> String {
        func titleList(_ tasks: [TaskItem]) -> String {
            let shown = tasks.prefix(3).map(\.title).joined(separator: ", ")
            let remaining = tasks.count - 3
            return remaining > 0 ? "\(shown), and \(remaining) more" : shown
        }

        if !dueToday.isEmpty && !overdue.isEmpty {
            return "\(dueToday.count) due today, \(overdue.count) overdue: \(titleList(dueToday + overdue))"
        } else if !dueToday.isEmpty {
            return "Due today: \(titleList(dueToday))"
        } else if !overdue.isEmpty {
            return "\(overdue.count) task\(overdue.count == 1 ? "" : "s") overdue: \(titleList(overdue))"
        } else {
            return "Check your tasks for today"
        }
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
