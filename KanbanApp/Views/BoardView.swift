import SwiftUI

/// The board shows one computed column ("Deadline Missed") alongside the
/// real, persisted ColumnStatus ones — a task lands there automatically
/// once its due date has passed and it isn't Done, regardless of which
/// status it's actually stored under. It's not a manual drop target since
/// "missed" isn't something you assign; dragging a card out of it (e.g.
/// to Done, or back to a normal column) uses the normal status update.
private enum BoardColumn: Identifiable {
    case status(ColumnStatus)
    case missed

    static let all: [BoardColumn] = [
        .status(.backlog), .status(.todo), .status(.inProgress), .status(.done), .missed
    ]

    var id: String {
        switch self {
        case .status(let s): return s.id
        case .missed: return "missed"
        }
    }

    var title: String {
        switch self {
        case .status(let s): return s.rawValue
        case .missed: return "Deadline Missed"
        }
    }

    var isMissed: Bool {
        if case .missed = self { return true }
        return false
    }
}

struct BoardView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var editor: EditorState

    var searchText: String = ""
    var priorityFilter: TaskPriority? = nil

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(BoardColumn.all) { column in
                    columnView(for: column)
                }
            }
            .padding()
        }
    }

    private func isMissed(_ task: TaskItem) -> Bool {
        guard task.status != .done, let due = task.dueDate else { return false }
        return due < Calendar.current.startOfDay(for: Date())
    }

    private func matchesFilters(_ task: TaskItem) -> Bool {
        if let priorityFilter, task.priority != priorityFilter { return false }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let query = searchText.lowercased()
            guard task.title.lowercased().contains(query) || task.notes.lowercased().contains(query) else {
                return false
            }
        }
        return true
    }

    private func tasks(for column: BoardColumn) -> [TaskItem] {
        let base: [TaskItem]
        switch column {
        case .missed:
            base = store.tasks.filter { isMissed($0) }
        case .status(let status):
            base = store.tasks.filter { $0.status == status && !isMissed($0) }
        }
        return base.filter(matchesFilters).sorted { $0.sortOrder < $1.sortOrder }
    }

    private func columnView(for column: BoardColumn) -> some View {
        let columnTasks = tasks(for: column)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(column.title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(column.isMissed ? Theme.priorityHigh : .secondary)
                    .tracking(0.4)

                Spacer()

                Text("\(columnTasks.count)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.columnBackground))
                    .overlay(Capsule().stroke(Theme.cardBorder))
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                if columnTasks.isEmpty {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Theme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(height: 56)
                        .overlay(
                            Text("No tasks")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        )
                } else {
                    ForEach(columnTasks) { task in
                        TaskCardView(task: task, isMissed: column.isMissed)
                            .onTapGesture { editor.target = .edit(task) }
                            .draggable(task.id.uuidString)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(column.isMissed ? Theme.missedColumnBackground : Theme.columnBackground)
            )
            .overlay {
                if column.isMissed {
                    RoundedRectangle(cornerRadius: 10).stroke(Theme.missedBorder)
                }
            }
            .modifier(DropSupport(column: column, store: store))
        }
        .frame(width: 200)
    }
}

/// Only real status columns accept drops — "Deadline Missed" is computed,
/// not something you assign by dragging a card into it.
private struct DropSupport: ViewModifier {
    let column: BoardColumn
    let store: TaskStore

    func body(content: Content) -> some View {
        if case .status(let status) = column {
            content.dropDestination(for: String.self) { items, _ in
                guard let idString = items.first,
                      let uuid = UUID(uuidString: idString),
                      let dropped = store.tasks.first(where: { $0.id == uuid }) else { return false }
                store.move(dropped, to: status)
                return true
            }
        } else {
            content
        }
    }
}

struct TaskCardView: View {
    let task: TaskItem
    var isMissed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)

                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)

                Spacer(minLength: 0)

                PriorityBadge(priority: task.priority)
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let due = task.dueDate {
                HStack(spacing: 4) {
                    Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    if task.recurrence != .none {
                        Image(systemName: "repeat")
                            .help(task.recurrence.rawValue)
                    }
                }
                .font(.caption2)
                .foregroundStyle(isMissed ? Theme.priorityHigh : .secondary)
            }

            if let minutes = task.estimatedMinutes {
                Label(minutes.formattedAsDuration, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(isMissed ? Theme.missedCardBackground : Theme.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isMissed ? Theme.missedBorder : Theme.cardBorder))
    }
}

struct PriorityBadge: View {
    let priority: TaskPriority

    var body: some View {
        Text(priority.rawValue)
            .font(.system(size: 9, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.16)))
            .foregroundStyle(color)
    }

    private var color: Color {
        switch priority {
        case .low: return Theme.priorityLow
        case .medium: return Theme.priorityMedium
        case .high: return Theme.priorityHigh
        }
    }
}
