import SwiftUI

struct SettingsView: View {
    @AppStorage("launchAtLoginEnabled") private var launchAtLoginEnabled: Bool = true

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
        }
        .padding(16)
        .frame(width: 260)
    }
}
