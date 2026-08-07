import Foundation
import SwiftData

enum PersistenceController {
    static let shared: ModelContainer = {
        let schema = Schema([TaskItem.self])
        let config = ModelConfiguration(schema: schema, url: AppGroup.storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()
}
