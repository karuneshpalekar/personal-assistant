import SwiftUI

@MainActor
struct DoneListView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var editor: EditorState

    var searchText: String = ""
    var priorityFilter: TaskPriority? = nil
    var dateFilter: Date? = nil

    private var doneTasks: [TaskItem] {
        store.tasks
            .filter { $0.status == .done }
            .filter(matchesFilters)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func matchesFilters(_ task: TaskItem) -> Bool {
        if let priorityFilter, task.priority != priorityFilter { return false }
        if let dateFilter {
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

    var body: some View {
        if doneTasks.isEmpty {
            ContentUnavailableView(
                "No completed tasks",
                systemImage: "checkmark.circle",
                description: Text("Finished tasks show up here")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(doneTasks) { task in
                        DoneRow(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { editor.target = .edit(task) }
                        Divider()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

@MainActor
private struct DoneRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Tag.fine.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .fontWeight(.medium)
                    .strikethrough()
                    .foregroundStyle(.secondary)

                if let due = task.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let minutes = task.estimatedMinutes {
                Label(minutes.formattedAsDuration, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TagBadge(text: task.priority.rawValue, tag: task.priority.tag)
        }
        .padding(.vertical, 9)
    }
}
