import Foundation

enum SharedStorage {
    static var storeURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = appSupport.appendingPathComponent("PersonalAssistant", isDirectory: true)
        migrateFromKanbanTimelineIfNeeded(appSupport: appSupport, newDir: dir)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("tasks.json")
    }

    /// One-time migration for anyone upgrading from the app's previous name
    /// (Kanban Timeline) — moves existing task data forward instead of
    /// silently orphaning it under the old folder.
    private static func migrateFromKanbanTimelineIfNeeded(appSupport: URL, newDir: URL) {
        let oldDir = appSupport.appendingPathComponent("KanbanTimeline", isDirectory: true)
        let fm = FileManager.default
        guard !fm.fileExists(atPath: newDir.path), fm.fileExists(atPath: oldDir.path) else { return }
        try? fm.moveItem(at: oldDir, to: newDir)
    }
}
