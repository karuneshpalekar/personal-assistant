import EventKit
import Foundation

/// Mirrors pending tasks into a dedicated "Kanban Timeline" Reminders list.
/// Reminders already syncs across devices via iCloud and delivers native
/// notifications on iPhone — so this needs no push infrastructure, no
/// third-party service, and no paid Apple Developer account.
final class RemindersSync {
    static let shared = RemindersSync()
    private let store = EKEventStore()
    private let listTitle = "Kanban Timeline"
    private let mappingKey = "reminderIdentifierMapping"

    private init() {}

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
    }

    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestFullAccessToReminders { granted, error in
            if let error {
                print("Reminders access error: \(error)")
            }
            DispatchQueue.main.async { completion(granted) }
        }
    }

    private var mapping: [String: String] {
        get { (UserDefaults.standard.dictionary(forKey: mappingKey) as? [String: String]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: mappingKey) }
    }

    private func kanbanCalendar() -> EKCalendar? {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == listTitle }) {
            return existing
        }
        guard let source = store.defaultCalendarForNewReminders()?.source
            ?? store.sources.first(where: { $0.sourceType == .local })
            ?? store.sources.first else { return nil }

        let calendar = EKCalendar(for: .reminder, eventStore: store)
        calendar.title = listTitle
        calendar.source = source
        do {
            try store.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("Failed to create Reminders list: \(error)")
            return nil
        }
    }

    /// Creates or updates the Reminders entry for a task. A task that's
    /// Done gets its reminder removed rather than marked complete, since a
    /// recurring task will bounce right back to pending with a new date.
    func sync(_ task: TaskItem) {
        guard isAuthorized else { return }

        guard task.status != .done else {
            remove(task)
            return
        }

        let reminder: EKReminder
        if let identifier = mapping[task.id.uuidString],
           let existing = store.calendarItem(withIdentifier: identifier) as? EKReminder {
            reminder = existing
        } else {
            reminder = EKReminder(eventStore: store)
            reminder.calendar = kanbanCalendar()
        }

        reminder.title = task.title
        reminder.notes = task.notes.isEmpty ? nil : task.notes
        reminder.priority = priorityValue(for: task.priority)
        reminder.isCompleted = false
        reminder.alarms?.forEach { reminder.removeAlarm($0) }

        if let due = task.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: due
            )
            let dayBefore = due.addingTimeInterval(-24 * 60 * 60)
            if dayBefore > Date() {
                reminder.addAlarm(EKAlarm(absoluteDate: dayBefore))
            } else if due > Date() {
                reminder.addAlarm(EKAlarm(absoluteDate: due))
            }
        } else {
            reminder.dueDateComponents = nil
        }

        do {
            try store.save(reminder, commit: true)
            var m = mapping
            m[task.id.uuidString] = reminder.calendarItemIdentifier
            mapping = m
        } catch {
            print("Failed to sync reminder for '\(task.title)': \(error)")
        }
    }

    func remove(_ task: TaskItem) {
        defer {
            var m = mapping
            m.removeValue(forKey: task.id.uuidString)
            mapping = m
        }
        guard isAuthorized,
              let identifier = mapping[task.id.uuidString],
              let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder else { return }
        try? store.remove(reminder, commit: true)
    }

    /// Re-syncs every task — call once after the user turns syncing on so
    /// existing tasks aren't left out.
    func syncAll(_ tasks: [TaskItem]) {
        for task in tasks {
            sync(task)
        }
    }

    private func priorityValue(for priority: TaskPriority) -> Int {
        switch priority {
        case .low: return 9
        case .medium: return 5
        case .high: return 1
        }
    }
}
