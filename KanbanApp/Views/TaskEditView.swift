import SwiftUI

struct TaskEditView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var editor: EditorState

    let task: TaskItem?

    @FocusState private var titleFocused: Bool
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var status: ColumnStatus = .backlog
    @State private var priority: TaskPriority = .medium
    @State private var startDate: Date = Date()
    @State private var hasStartDate = false
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = true
    @State private var recurrence: RecurrenceRule = .none

    var body: some View {
        Form {
            TextField("Title", text: $title)
                .focused($titleFocused)
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

                Picker("Repeat", selection: $recurrence) {
                    ForEach(RecurrenceRule.allCases) { Text($0.rawValue).tag($0) }
                }
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
        .onAppear {
            load()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                titleFocused = true
            }
        }
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
        recurrence = task.recurrence
    }

    private func save() {
        var target = task ?? TaskItem(title: title)
        target.title = title
        target.notes = notes
        target.status = status
        target.priority = priority
        target.startDate = hasStartDate ? startDate : nil
        target.dueDate = hasDueDate ? dueDate : nil
        target.recurrence = hasDueDate ? recurrence : .none
        store.upsert(target)
        dismiss()
    }

    private func delete() {
        guard let task else { return }
        store.delete(task)
        dismiss()
    }
}
