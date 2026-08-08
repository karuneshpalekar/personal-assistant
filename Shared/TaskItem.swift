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

enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    /// Interval to add to a due date to compute the next occurrence, nil for `.none`.
    var dateComponents: DateComponents? {
        switch self {
        case .none: return nil
        case .daily: return DateComponents(day: 1)
        case .weekly: return DateComponents(day: 7)
        case .monthly: return DateComponents(month: 1)
        case .yearly: return DateComponents(year: 1)
        }
    }
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
    var recurrence: RecurrenceRule

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        status: ColumnStatus = .backlog,
        priority: TaskPriority = .medium,
        startDate: Date? = nil,
        dueDate: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        recurrence: RecurrenceRule = .none
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
        self.recurrence = recurrence
    }

    // Custom decoding so tasks saved before `recurrence` existed still load
    // (plain Codable synthesis would fail on the missing key otherwise).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        status = try container.decode(ColumnStatus.self, forKey: .status)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        recurrence = try container.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence) ?? .none
    }
}
