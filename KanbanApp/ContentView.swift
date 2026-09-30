import SwiftUI

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    case done = "Done"
    var id: String { rawValue }
}

@MainActor
struct ContentView: View {
    @EnvironmentObject private var editor: EditorState
    @EnvironmentObject private var panelState: PanelState
    @EnvironmentObject private var store: TaskStore
    @AppStorage("appearanceMode") private var appearanceRaw: String = AppearanceMode.system.rawValue
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var priorityFilter: TaskPriority?
    @State private var dateFilter: Date?
    @State private var showingDateFilterPicker = false
    @State private var noDistractionMode = false

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    private var openCount: Int {
        store.tasks.filter { $0.status != .done }.count
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                filterBar
                Divider()

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .modifier(FadeIn())
                    .id(panelState.mode)

                Divider()
                footer
            }

            if let target = editor.target {
                Color.black.opacity(0.28).ignoresSafeArea()
                    .onTapGesture { editor.target = nil }

                TaskEditView(task: target.task)
                    .padding(22)
                    .transition(.opacity)
                    .animation(Motion.swap, value: editor.target)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .preferredColorScheme(appearance.colorScheme)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 7) {
                    Image(systemName: "square.grid.2x2.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Personal Assistant").font(.title3.weight(.semibold))
                }
                Text("Track work as it moves across your board")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Button {
                store.load()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Button {
                editor.target = .new
            } label: {
                Label("New task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)

            AppearanceToggle()

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
                panelState.isHidden = true
            } label: {
                Image(systemName: "eye.slash")
            }
            .buttonStyle(.borderless)
            .help("Hide board — click the menu bar icon to bring it back")
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(DragHandle())
    }

    // MARK: Filters

    private var filterBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search by title or notes", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: 240)

            HStack(spacing: 6) {
                FilterChip(title: "All", selected: priorityFilter == nil) { priorityFilter = nil }
                ForEach(TaskPriority.allCases) { p in
                    FilterChip(title: p.rawValue, selected: priorityFilter == p) { priorityFilter = p }
                }
            }

            Button {
                showingDateFilterPicker = true
            } label: {
                if let dateFilter {
                    Label(dateFilter.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                } else {
                    Label("Any date", systemImage: "calendar")
                }
            }
            .buttonStyle(.bordered)
            .fixedSize()
            .popover(isPresented: $showingDateFilterPicker) {
                DateFilterPopover(dateFilter: $dateFilter, isPresented: $showingDateFilterPicker)
            }

            Picker("", selection: $panelState.mode.animation(Motion.screen)) {
                ForEach(BoardMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)

            Spacer()

            Toggle(isOn: $noDistractionMode.animation(Motion.swap)) {
                Label("No distraction", systemImage: "target")
            }
            .toggleStyle(.button)
            .help("Show only tasks due today or tomorrow")
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch panelState.mode {
        case .kanban:
            BoardView(
                searchText: searchText,
                priorityFilter: priorityFilter,
                dateFilter: dateFilter,
                noDistractionMode: noDistractionMode
            )
        case .timeline:
            TimelineView()
        case .done:
            DoneListView(searchText: searchText, priorityFilter: priorityFilter, dateFilter: dateFilter)
        }
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 4) {
            Text("\(openCount) open").fontWeight(.semibold).monospacedDigit()
                + Text(" task\(openCount == 1 ? "" : "s")").foregroundStyle(.secondary)
            Spacer()
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.bar)
    }
}

@MainActor
struct DateFilterPopover: View {
    @EnvironmentObject private var store: TaskStore
    @Binding var dateFilter: Date?
    @Binding var isPresented: Bool
    @State private var pickedDate: Date = Date()

    private var countOnPickedDate: Int {
        store.tasks.filter { task in
            guard let due = task.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: pickedDate)
        }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            DatePicker("", selection: $pickedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()

            Text("\(countOnPickedDate) task\(countOnPickedDate == 1 ? "" : "s") due on this date")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Clear") {
                    dateFilter = nil
                    isPresented = false
                }
                Spacer()
                Button("Apply") {
                    dateFilter = pickedDate
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            pickedDate = dateFilter ?? Date()
        }
    }
}
