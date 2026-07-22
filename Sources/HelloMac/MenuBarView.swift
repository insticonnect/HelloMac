import SwiftUI
import AppKit

/// The popover shown from the menu bar icon.
struct MenuBarView: View {
    @ObservedObject var tracker: Tracker
    let store: Store
    let openDashboard: () -> Void

    @State private var paused = Config.shared.paused
    @State private var activeToday = ""
    @State private var importantCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("HelloMac").font(.headline)
                Spacer()
                Circle()
                    .fill(paused ? Color.orange : Color.green)
                    .frame(width: 9, height: 9)
                Text(paused ? "Paused" : "Tracking")
                    .font(.caption).foregroundColor(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(tracker.isIdle ? "Idle" : tracker.currentAppName)
                    .font(.system(size: 13, weight: .semibold))
                if !tracker.currentWindowTitle.isEmpty && !tracker.isIdle {
                    Text(tracker.currentWindowTitle)
                        .font(.caption).foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Active today").font(.caption2).foregroundColor(.secondary)
                    Text(activeToday).font(.system(size: 15, weight: .bold))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Needs attention").font(.caption2).foregroundColor(.secondary)
                    Text("\(importantCount)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(importantCount > 0 ? .orange : .primary)
                }
            }

            Divider()

            Button(action: openDashboard) {
                Label("Open Dashboard", systemImage: "rectangle.on.rectangle")
                    .frame(maxWidth: .infinity)
            }

            Button(action: togglePause) {
                Label(paused ? "Resume Tracking" : "Pause Tracking",
                      systemImage: paused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }

            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit HelloMac", systemImage: "power")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear(perform: refresh)
    }

    private func togglePause() {
        Config.shared.paused.toggle()
        Config.shared.save()
        paused = Config.shared.paused
    }

    private func refresh() {
        paused = Config.shared.paused
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let stats = store.statsForDate(fmt.string(from: Date()))
        activeToday = Digest.formatDuration(stats.active)
        let imp = store.importantToday()
        let dueSoon = (imp["due_soon"] as? [[String: Any]])?.count ?? 0
        let revisions = (imp["revisions_today"] as? [[String: Any]])?.count ?? 0
        importantCount = dueSoon + revisions
    }
}
