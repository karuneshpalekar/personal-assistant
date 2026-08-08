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
    case weekdays = "Weekdays"
    case weekend = "Weekend"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    /// The next date this rule should fire on, after `date`. `.weekdays`
    /// skips Sat/Sun; `.weekend` skips Mon–Fri. Nil for `.none`.
    func nextDate(after date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekdays:
            var next = calendar.date(byAdding: .day, value: 1, to: date)!
            while calendar.isDateInWeekend(next) {
                next = calendar.date(byAdding: .day, value: 1, to: next)!
            }
            return next
        case .weekend:
            var next = calendar.date(byAdding: .day, value: 1, to: date)!
            while !calendar.isDateInWeekend(next) {
                next = calendar.date(byAdding: .day, value: 1, to: next)!
            }
            return next
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
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
    /// Estimated time to complete, in minutes. Nil means no estimate set.
    var estimatedMinutes: Int?

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
        recurrence: RecurrenceRule = .none,
        estimatedMinutes: Int? = nil
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
        self.estimatedMinutes = estimatedMinutes
    }

    // Custom decoding so tasks saved before `recurrence`/`estimatedMinutes`
    // existed still load (plain Codable synthesis would fail on missing
    // keys otherwise).
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
        estimatedMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedMinutes)
    }
}

extension Int {
    /// Formats a minute count as "1h 30m" / "1h" / "45m".
    var formattedAsDuration: String {
        let h = self / 60
        let m = self % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}
