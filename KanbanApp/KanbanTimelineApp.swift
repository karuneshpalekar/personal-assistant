import SwiftUI
import SwiftData

@main
struct KanbanTimelineApp: App {
    @StateObject private var editorState = EditorState()

    var body: some Scene {
        MenuBarExtra("Kanban Timeline", systemImage: "square.grid.3x2") {
            ContentView()
                .frame(width: 820, height: 560)
                .environmentObject(editorState)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(PersistenceController.shared)
    }
}
