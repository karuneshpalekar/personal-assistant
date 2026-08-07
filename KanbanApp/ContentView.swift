import SwiftUI
import SwiftData

enum BoardMode: String, CaseIterable, Identifiable {
    case kanban = "Board"
    case timeline = "Timeline"
    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject private var editor: EditorState
    @State private var mode: BoardMode = .kanban

    var body: some View {
        ZStack {
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

            if let target = editor.target {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { editor.target = nil }
                    .transition(.opacity)

                TaskEditView(task: target.task)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .windowBackgroundColor)))
                    .shadow(radius: 20)
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.15), value: editor.target?.id)
    }
}
