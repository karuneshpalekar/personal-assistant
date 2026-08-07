import Foundation
import SwiftData

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

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String
    var statusRaw: String
    var priorityRaw: String
    var startDate: Date?
    var dueDate: Date?
    var sortOrder: Int
    var createdAt: Date

    var status: ColumnStatus {
        get { ColumnStatus(rawValue: statusRaw) ?? .backlog }
        set { statusRaw = newValue.rawValue }
    }

    var priority: TaskPriority {
        get { TaskPriority(rawValue: priorityRaw) ?? .medium }
        set { priorityRaw = newValue.rawValue }
    }

    init(
        title: String,
        notes: String = "",
        status: ColumnStatus = .backlog,
        priority: TaskPriority = .medium,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.statusRaw = status.rawValue
        self.priorityRaw = priority.rawValue
        self.startDate = startDate
        self.dueDate = dueDate
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
