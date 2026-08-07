import SwiftUI
import SwiftData

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    var id: String { rawValue }
}

struct ContentView: View {
    @State private var mode: BoardMode = .kanban
    @State private var showingNewTask = false

    var body: some View {
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
                    showingNewTask = true
                } label: {
                    Label("New Task", systemImage: "plus")
                }
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
        .sheet(isPresented: $showingNewTask) {
            TaskEditView(task: nil)
        }
    }
}
