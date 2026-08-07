import SwiftUI
import SwiftData

@main
struct KanbanTimelineApp: App {
    var body: some Scene {
        MenuBarExtra("Kanban Timeline", systemImage: "square.grid.3x2") {
            ContentView()
                .frame(width: 820, height: 560)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(PersistenceController.shared)
    }
}
