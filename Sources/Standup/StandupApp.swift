import SwiftUI
import AppKit
import StandupCore

@main
struct StandupApp: App {
    @StateObject private var tracker = ActivityTracker()
    private let reminderOverlayController = ReminderOverlayController()
    
    init() {
        // Configure the app to run as an accessory (menubar only, no Dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuContentView(tracker: tracker)
        } label: {
            HStack(spacing: 4) {
                AnimatedMenuBarIcon(tracker: tracker)
                
                if !tracker.isIdle {
                    Text(formatShortTime(tracker.activeSeconds))
                        .font(.system(.caption, design: .monospaced))
                } else {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                }
            }
            .onAppear {
                if tracker.needsStandUp {
                    reminderOverlayController.show(tracker: tracker)
                }
            }
            .onChange(of: tracker.needsStandUp) { needsStandUp in
                if needsStandUp {
                    reminderOverlayController.show(tracker: tracker)
                } else {
                    reminderOverlayController.hide()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func formatShortTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        return "\(mins)m"
    }
}
