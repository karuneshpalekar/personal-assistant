import Foundation

enum ColumnStatus: String, Codable, CaseIterable, Identifiable {
    case backlog = "Backlog"
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"

    var id: String { rawValue }
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var notes: String
    var status: ColumnStatus
    var priority: TaskPriority
    var startDate: Date?
    var dueDate: Date?
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        status: ColumnStatus = .backlog,
        priority: TaskPriority = .medium,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.status = status
        self.priority = priority
        self.startDate = startDate
        self.dueDate = dueDate
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
