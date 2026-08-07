import SwiftUI

struct BoardView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var editor: EditorState

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(ColumnStatus.allCases) { status in
                    columnView(for: status)
                }
            }
            .padding()
        }
    }

    private func tasks(for status: ColumnStatus) -> [TaskItem] {
        store.tasks.filter { $0.status == status }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private func columnView(for status: ColumnStatus) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status.rawValue)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(tasks(for: status)) { task in
                    TaskCardView(task: task)
                        .onTapGesture { editor.target = .edit(task) }
                        .draggable(task.id.uuidString)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.columnBackground))
            .dropDestination(for: String.self) { items, _ in
                guard let idString = items.first,
                      let uuid = UUID(uuidString: idString),
                      let dropped = store.tasks.first(where: { $0.id == uuid }) else { return false }
                store.move(dropped, to: status)
                return true
            }
        }
        .frame(width: 190)
    }
}

struct TaskCardView: View {
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)

            if let due = task.dueDate {
                Label(due.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 6, height: 6)
                Text(task.priority.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder))
    }

    private var priorityColor: Color {
        switch task.priority {
        case .low: return Theme.priorityLow
        case .medium: return Theme.priorityMedium
        case .high: return Theme.priorityHigh
        }
    }
}
