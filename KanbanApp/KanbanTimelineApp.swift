import SwiftUI

@main
struct KanbanTimelineApp: App {
    @StateObject private var editorState = EditorState()
    @StateObject private var taskStore = TaskStore()

    var body: some Scene {
        MenuBarExtra("Kanban Timeline", systemImage: "square.grid.3x2") {
            ContentView()
                .frame(width: 820, height: 560)
                .environmentObject(editorState)
                .environmentObject(taskStore)
        }
        .menuBarExtraStyle(.window)
    }
}
