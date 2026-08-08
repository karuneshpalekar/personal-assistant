import SwiftUI

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    var id: String { rawValue }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var editor: EditorState
    @EnvironmentObject private var panelState: PanelState
    @EnvironmentObject private var store: TaskStore
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue
    @State private var mode: BoardMode = .kanban
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var priorityFilter: TaskPriority?

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
        ZStack {
            if panelState.isCollapsed {
                CompactPillView()
            } else {
                VStack(spacing: 0) {
                    header
                    filterBar

                    Divider()

                    switch mode {
                    case .kanban:
                        BoardView(searchText: searchText, priorityFilter: priorityFilter)
                    case .timeline:
                        TimelineView()
                    }
                }

                if let target = editor.target {
                    Color.black.opacity(0.25)
                        .onTapGesture { editor.target = nil }

                    TaskEditView(task: target.task)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.cardBackground))
                        .shadow(radius: 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.panelBackground)
        .tint(Theme.accent)
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Kanban Timeline")
                    .font(.title2.bold())
                Text("Track work as it moves across your board")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    store.load()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Button {
                    editor.target = .new
                } label: {
                    Label("New Task", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Menu {
                    ForEach(AppearanceMode.allCases) { mode in
                        Button {
                            appearanceModeRaw = mode.rawValue
                        } label: {
                            if mode == appearanceMode {
                                Label(mode.rawValue, systemImage: "checkmark")
                            } else {
                                Text(mode.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: appearanceMode.icon)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Appearance")

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                .popover(isPresented: $showingSettings, arrowEdge: .bottom) {
                    SettingsView()
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
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 10)
        .background(DragHandle())
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by title or notes…", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Theme.columnBackground))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardBorder))
            .frame(maxWidth: 260)

            Menu {
                Button("All priorities") { priorityFilter = nil }
                ForEach(TaskPriority.allCases) { p in
                    Button(p.rawValue) { priorityFilter = p }
                }
            } label: {
                Text(priorityFilter?.rawValue ?? "All priorities")
            }
            .fixedSize()

            Picker("", selection: $mode) {
                ForEach(BoardMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 160)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
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
                    .fill(Theme.accent.gradient)
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
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                panelState.isCollapsed = false
            }
        }
    }
}
