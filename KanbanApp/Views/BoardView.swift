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

@MainActor
struct BoardView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var editor: EditorState

    var searchText: String = ""
    var priorityFilter: TaskPriority? = nil
    var dateFilter: Date? = nil
    var noDistractionMode: Bool = false

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
        if noDistractionMode {
            guard let due = task.dueDate else { return false }
            let calendar = Calendar.current
            guard calendar.isDateInToday(due) || calendar.isDateInTomorrow(due) else { return false }
        } else if let dateFilter {
            guard let due = task.dueDate, Calendar.current.isDate(due, inSameDayAs: dateFilter) else {
                return false
            }
        }
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(column.isMissed ? Tag.urgent.color : .secondary)
                    .tracking(0.4)

                Spacer()

                Text("\(columnTasks.count)")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.background.secondary, in: Capsule())
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                if columnTasks.isEmpty {
                    ContentUnavailableView {
                        Label("No tasks", systemImage: "tray")
                    }
                    .scaleEffect(0.7)
                    .frame(height: 70)
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
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
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

@MainActor
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
                    .fontWeight(.medium)
                    .lineLimit(2)

                Spacer(minLength: 0)

                TagBadge(text: task.priority.rawValue, tag: task.priority.tag)
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.caption)
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
                .font(.caption)
                .foregroundStyle(isMissed ? Tag.urgent.color : .secondary)
            }

            if let minutes = task.estimatedMinutes {
                Label(minutes.formattedAsDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(isMissed ? AnyCardStyle.missed : AnyCardStyle.normal)
    }
}

/// Lets a card pick between the two card-style modifiers at runtime.
private enum AnyCardStyle: ViewModifier {
    case normal, missed

    func body(content: Content) -> some View {
        switch self {
        case .normal: content.cardStyle()
        case .missed: content.missedCardStyle()
        }
    }
}
