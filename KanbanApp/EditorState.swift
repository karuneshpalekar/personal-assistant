import SwiftUI

enum EditorTarget: Identifiable, Equatable {
    case new
    case edit(TaskItem)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let task): return task.id.uuidString
        }
    }

    var task: TaskItem? {
        if case .edit(let task) = self { return task }
        return nil
    }
}

final class EditorState: ObservableObject {
    @Published var target: EditorTarget?
}
