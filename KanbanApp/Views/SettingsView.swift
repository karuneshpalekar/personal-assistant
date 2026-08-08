import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("launchAtLoginEnabled") private var launchAtLoginEnabled: Bool = true
    @AppStorage("remindersSyncEnabled") private var remindersSyncEnabled: Bool = false
    @State private var remindersPermissionDenied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.headline)

            Toggle("Launch at Login", isOn: $launchAtLoginEnabled)
                .onChange(of: launchAtLoginEnabled) { _, newValue in
                    LaunchAtLogin.setEnabled(newValue)
                }

            Text("Keeps the app running so the daily reminder and deadline alerts can fire when your Mac wakes.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Toggle("Sync to Reminders (iPhone alerts)", isOn: $remindersSyncEnabled)
                .onChange(of: remindersSyncEnabled) { _, newValue in
                    guard newValue else { return }
                    RemindersSync.shared.requestAccess { granted in
                        if granted {
                            RemindersSync.shared.syncAll(store.tasks)
                        } else {
                            remindersSyncEnabled = false
                            remindersPermissionDenied = true
                        }
                    }
                }

            Text("Mirrors open tasks into a \"Kanban Timeline\" Reminders list, which iCloud syncs to your iPhone — due-date alerts show up there as native notifications.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if remindersPermissionDenied {
                Text("Reminders access was denied. Enable it in System Settings > Privacy & Security > Reminders.")
                    .font(.caption)
                    .foregroundStyle(Theme.priorityHigh)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
