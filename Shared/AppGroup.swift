import Foundation

enum AppGroup {
    static let identifier = "group.com.karunesh.kanbantimeline"

    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            fatalError("App Group container '\(identifier)' is not configured. Check entitlements.")
        }
        return url
    }

    static var storeURL: URL {
        containerURL.appendingPathComponent("KanbanTimeline.sqlite")
    }
}
