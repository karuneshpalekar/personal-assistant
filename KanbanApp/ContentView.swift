import SwiftUI

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject private var editor: EditorState
    @State private var mode: BoardMode = .kanban

    var body: some View {
        if let target = editor.target {
            TaskEditView(task: target.task)
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
        }
    }
}
