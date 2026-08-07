import SwiftUI

enum TimelineMode: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case gantt = "Gantt"
    var id: String { rawValue }
}

struct TimelineView: View {
    @State private var timelineMode: TimelineMode = .calendar
    @State private var monthAnchor: Date = Date()

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $timelineMode) {
                ForEach(TimelineMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .padding([.horizontal, .top], 12)

            switch timelineMode {
            case .calendar:
                CalendarMonthView(monthAnchor: $monthAnchor)
            case .gantt:
                GanttView()
            }
        }
    }
}

// MARK: - Calendar

struct CalendarMonthView: View {
    @Binding var monthAnchor: Date
    @EnvironmentObject private var store: TaskStore
    private var tasks: [TaskItem] { store.tasks }

    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthAnchor),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else { return [] }
        let start = firstWeek.start
        guard let monthEnd = calendar.dateInterval(of: .month, for: monthAnchor)?.end,
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: calendar.date(byAdding: .day, value: -1, to: monthEnd)!) else { return [] }
        let end = lastWeek.end

        var days: [Date] = []
        var current = start
        while current < end {
            days.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return days
    }

    private func tasks(on day: Date) -> [TaskItem] {
        tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return calendar.isDate(due, inSameDayAs: day)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { shiftMonth(-1) }) { Image(systemName: "chevron.left") }
                Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Button(action: { shiftMonth(1) }) { Image(systemName: "chevron.right") }
                Spacer()
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(daysInMonth, id: \.self) { day in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(calendar.component(.day, from: day))")
                            .font(.caption2)
                            .foregroundStyle(calendar.isDate(day, equalTo: monthAnchor, toGranularity: .month) ? .primary : .secondary)
                        ForEach(tasks(on: day).prefix(3)) { task in
                            Text(task.title)
                                .font(.caption2)
                                .lineLimit(1)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.2)))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.gray.opacity(0.06)))
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding(.top, 8)
    }

    private func shiftMonth(_ delta: Int) {
        monthAnchor = calendar.date(byAdding: .month, value: delta, to: monthAnchor) ?? monthAnchor
    }
}

// MARK: - Gantt

struct GanttView: View {
    @EnvironmentObject private var store: TaskStore
    private var tasks: [TaskItem] { store.tasks.sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) } }

    private var scheduled: [TaskItem] {
        tasks.filter { $0.startDate != nil || $0.dueDate != nil }
    }

    private var rangeStart: Date {
        scheduled.compactMap { $0.startDate ?? $0.dueDate }.min() ?? Date()
    }

    private var totalDays: Int {
        let end = scheduled.compactMap { $0.dueDate ?? $0.startDate }.max() ?? Date()
        return max(1, Calendar.current.dateComponents([.day], from: rangeStart, to: end).day ?? 1) + 1
    }

    private let dayWidth: CGFloat = 24

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(scheduled) { task in
                    HStack(spacing: 0) {
                        Text(task.title)
                            .font(.caption)
                            .frame(width: 140, alignment: .leading)
                            .lineLimit(1)

                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.gray.opacity(0.1))
                                .frame(width: CGFloat(totalDays) * dayWidth, height: 18)

                            Capsule()
                                .fill(barColor(task))
                                .frame(width: barWidth(task), height: 18)
                                .offset(x: barOffset(task))
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func dayOffset(_ date: Date) -> Int {
        Calendar.current.dateComponents([.day], from: rangeStart, to: date).day ?? 0
    }

    private func barOffset(_ task: TaskItem) -> CGFloat {
        let start = task.startDate ?? task.dueDate ?? rangeStart
        return CGFloat(max(0, dayOffset(start))) * dayWidth
    }

    private func barWidth(_ task: TaskItem) -> CGFloat {
        let start = task.startDate ?? task.dueDate ?? rangeStart
        let end = task.dueDate ?? task.startDate ?? start
        let days = max(1, (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1)
        return CGFloat(days) * dayWidth
    }

    private func barColor(_ task: TaskItem) -> Color {
        switch task.priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
