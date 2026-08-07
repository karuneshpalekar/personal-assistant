import SwiftUI

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject private var editor: EditorState
    @EnvironmentObject private var panelState: PanelState
    @State private var mode: BoardMode = .kanban

    var body: some View {
        ZStack {
            if panelState.isCollapsed {
                CompactPillView()
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Picker("", selection: $mode) {
                            ForEach(BoardMode.allCases) { m in
                                Text(m.rawValue).tag(m)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)

                        Spacer()

                        Button {
                            editor.target = .new
                        } label: {
                            Label("New Task", systemImage: "plus")
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                panelState.isCollapsed = true
                            }
                        } label: {
                            Image(systemName: "arrow.down.right.and.arrow.up.left")
                        }
                        .buttonStyle(.borderless)
                        .help("Collapse to a compact pill")
                    }
                    .padding()

                    Divider()

                    switch mode {
                    case .kanban:
                        BoardView()
                    case .timeline:
                        TimelineView()
                    }
                }

                if let target = editor.target {
                    Color.black.opacity(0.25)
                        .onTapGesture { editor.target = nil }

                    TaskEditView(task: target.task)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .windowBackgroundColor)))
                        .shadow(radius: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct CompactPillView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var panelState: PanelState

    private var openCount: Int {
        store.tasks.filter { $0.status != .done }.count
    }

    private var dueTodayCount: Int {
        store.tasks.filter { task in
            guard let due = task.dueDate, task.status != .done else { return false }
            return Calendar.current.isDateInToday(due)
        }.count
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.gradient)
                    .frame(width: 34, height: 34)
                Image(systemName: "square.grid.3x2.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("\(openCount) open task\(openCount == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .semibold))
                Text(dueTodayCount > 0 ? "\(dueTodayCount) due today" : "Nothing due today")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.down.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.15)))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                panelState.isCollapsed = false
            }
        }
    }
}
