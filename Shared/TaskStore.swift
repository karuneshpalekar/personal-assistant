import Foundation
import Combine
import WidgetKit

/// Plain JSON-file-backed task store, shared between the app and the widget.
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
        WidgetCenter.shared.reloadAllTimelines()
    }

    func upsert(_ task: TaskItem) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
        } else {
            tasks.append(task)
        }
        save()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func move(_ task: TaskItem, to status: ColumnStatus) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[idx].status = status
        let maxOrder = tasks.filter { $0.status == status }.map(\.sortOrder).max() ?? 0
        tasks[idx].sortOrder = maxOrder + 1
        save()
    }

    /// One-shot read for contexts (like the widget) that don't want a live ObservableObject.
    static func loadTasks() -> [TaskItem] {
        guard let data = try? Data(contentsOf: SharedStorage.storeURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TaskItem].self, from: data)) ?? []
    }
}
