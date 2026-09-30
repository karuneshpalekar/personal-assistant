import SwiftUI

@MainActor
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
    @State private var hasEstimate = false
    @State private var estimateHours = 0
    @State private var estimateMinutes = 0

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

                if sameDayTaskCount >= 3 {
                    Label("\(sameDayTaskCount) tasks already due on this date", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Tag.urgent.color)
                }
            }

            Toggle("Time required", isOn: $hasEstimate)
            if hasEstimate {
                HStack {
                    Stepper("\(estimateHours) hr", value: $estimateHours, in: 0...24)
                        .monospacedDigit()
                    Stepper("\(estimateMinutes) min", value: $estimateMinutes, in: 0...55, step: 5)
                        .monospacedDigit()
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
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .frame(width: 380)
        .cardStyle(radius: 12)
        .shadow(radius: 20)
        .onAppear {
            load()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                titleFocused = true
            }
        }
    }

    private var sameDayTaskCount: Int {
        store.tasks.filter { other in
            guard let due = other.dueDate else { return false }
            if let task, other.id == task.id { return false }
            return Calendar.current.isDate(due, inSameDayAs: dueDate)
        }.count
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
        if let minutes = task.estimatedMinutes {
            hasEstimate = true
            estimateHours = minutes / 60
            estimateMinutes = minutes % 60
        }
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
        let totalMinutes = estimateHours * 60 + estimateMinutes
        target.estimatedMinutes = (hasEstimate && totalMinutes > 0) ? totalMinutes : nil
        store.upsert(target)
        dismiss()
    }

    private func delete() {
        guard let task else { return }
        store.delete(task)
        dismiss()
    }
}
