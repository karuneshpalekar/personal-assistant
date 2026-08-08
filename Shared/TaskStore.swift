import Foundation
import Combine

/// Plain JSON-file-backed task store.
/// (Not SwiftData: on this project's Xcode 15.3 toolchain, ModelContext.insert()
/// hangs indefinitely for reasons unrelated to this app's code — a plain
/// Codable + file store sidesteps that framework entirely.)
final class TaskStore: ObservableObject {
    @Published private(set) var tasks: [TaskItem] = []

    private let fileURL = SharedStorage.storeURL

    init() {
        load()
    }

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        tasks = (try? decoder.decode([TaskItem].self, from: data)) ?? []
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(tasks) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func upsert(_ task: TaskItem) {
        let finalTask = advanceIfRecurring(task)
        if let idx = tasks.firstIndex(where: { $0.id == finalTask.id }) {
            tasks[idx] = finalTask
        } else {
            tasks.append(finalTask)
        }
        save()
        NotificationManager.shared.scheduleDeadlineAlert(for: finalTask)
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
        NotificationManager.shared.cancelDeadlineAlert(for: task)
    }

    func move(_ task: TaskItem, to status: ColumnStatus) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].status = status
        let maxOrder = tasks.filter { $0.status == status }.map(\.sortOrder).max() ?? 0
        tasks[idx].sortOrder = maxOrder + 1
        tasks[idx] = advanceIfRecurring(tasks[idx])
        save()
        NotificationManager.shared.scheduleDeadlineAlert(for: tasks[idx])
    }

    /// If a recurring task is marked Done, roll it forward to its next
    /// occurrence (advance due/start dates, reset status) instead of
    /// letting it just sit completed.
    private func advanceIfRecurring(_ task: TaskItem) -> TaskItem {
        guard task.status == .done,
              task.recurrence != .none,
              let due = task.dueDate,
              let comp = task.recurrence.dateComponents else { return task }

        var next = task
        next.dueDate = Calendar.current.date(byAdding: comp, to: due) ?? due
        if let start = task.startDate {
            next.startDate = Calendar.current.date(byAdding: comp, to: start) ?? start
        }
        next.status = .todo
        return next
    }
}
