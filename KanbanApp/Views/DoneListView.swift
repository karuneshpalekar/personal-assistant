import SwiftUI

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
            VStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                Text("No completed tasks yet")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(doneTasks) { task in
                        DoneRow(task: task)
                            .onTapGesture { editor.target = .edit(task) }
                    }
                }
                .padding()
            }
        }
    }
}

private struct DoneRow: View {
    let task: TaskItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.priorityLow)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough()
                    .foregroundStyle(.secondary)

                if let due = task.dueDate {
                    Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let minutes = task.estimatedMinutes {
                Label(minutes.formattedAsDuration, systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            PriorityBadge(priority: task.priority)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Theme.cardBackground))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder))
    }
}
