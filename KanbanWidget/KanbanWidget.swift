import WidgetKit
import SwiftUI

struct TaskSnapshot: Identifiable {
    let id: UUID
    let title: String
    let dueDate: Date?
    let priority: TaskPriority
}

struct KanbanEntry: TimelineEntry {
    let date: Date
    let upcoming: [TaskSnapshot]
}

struct KanbanProvider: TimelineProvider {
    func placeholder(in context: Context) -> KanbanEntry {
        KanbanEntry(date: Date(), upcoming: [
            TaskSnapshot(id: UUID(), title: "Sample task", dueDate: Date(), priority: .medium)
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (KanbanEntry) -> Void) {
        completion(KanbanEntry(date: Date(), upcoming: fetchUpcoming()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KanbanEntry>) -> Void) {
        let entry = KanbanEntry(date: Date(), upcoming: fetchUpcoming())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func fetchUpcoming() -> [TaskSnapshot] {
        TaskStore.loadTasks()
            .filter { $0.status != .done }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .prefix(6)
            .map { TaskSnapshot(id: $0.id, title: $0.title, dueDate: $0.dueDate, priority: $0.priority) }
    }
}

struct KanbanWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: KanbanEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Upcoming Tasks")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if entry.upcoming.isEmpty {
                Text("Nothing scheduled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entry.upcoming.prefix(maxRows)) { task in
                    HStack(spacing: 6) {
                        Circle().fill(color(for: task.priority)).frame(width: 6, height: 6)
                        Text(task.title)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if let due = task.dueDate {
                            Text(due.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .widgetURL(URL(string: "kanbantimeline://open"))
    }

    private var maxRows: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 6
        }
    }

    private func color(for priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct KanbanWidget: Widget {
    let kind: String = "KanbanWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KanbanProvider()) { entry in
            KanbanWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Kanban Timeline")
        .description("Shows your upcoming tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
