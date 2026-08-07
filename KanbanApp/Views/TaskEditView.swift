import SwiftUI
import SwiftData
import WidgetKit

struct TaskEditView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var editor: EditorState

    let task: TaskItem?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var status: ColumnStatus = .backlog
    @State private var priority: TaskPriority = .medium
    @State private var startDate: Date = Date()
    @State private var hasStartDate = false
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = true

    var body: some View {
        Form {
            TextField("Title", text: $title)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...6)

            Picker("Status", selection: $status) {
                ForEach(ColumnStatus.allCases) { Text($0.rawValue).tag($0) }
            }
            Picker("Priority", selection: $priority) {
                ForEach(TaskPriority.allCases) { Text($0.rawValue).tag($0) }
            }

            Toggle("Start date", isOn: $hasStartDate)
            if hasStartDate {
                DatePicker("", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
            }

            Toggle("Due date", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("", selection: $dueDate, displayedComponents: .date)
                    .labelsHidden()
            }

            HStack {
                if task != nil {
                    Button("Delete", role: .destructive, action: delete)
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 380)
        .onAppear(perform: load)
    }

    private func dismiss() {
        editor.target = nil
    }

    private func load() {
        guard let task else { return }
        title = task.title
        notes = task.notes
        status = task.status
        priority = task.priority
        if let s = task.startDate { hasStartDate = true; startDate = s }
        if let d = task.dueDate { hasDueDate = true; dueDate = d }
    }

    private func save() {
        let target = task ?? TaskItem(title: title)
        if task == nil { context.insert(target) }
        target.title = title
        target.notes = notes
        target.status = status
        target.priority = priority
        target.startDate = hasStartDate ? startDate : nil
        target.dueDate = hasDueDate ? dueDate : nil
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }

    private func delete() {
        guard let task else { return }
        context.delete(task)
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
