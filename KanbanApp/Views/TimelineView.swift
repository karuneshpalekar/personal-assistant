import SwiftUI

struct TimelineView: View {
    @State private var monthAnchor: Date = Date()

    var body: some View {
        CalendarMonthView(monthAnchor: $monthAnchor)
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
