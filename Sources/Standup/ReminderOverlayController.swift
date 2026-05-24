import AppKit
import SwiftUI
import StandupCore

@MainActor
final class ReminderOverlayController {
    private var window: NSWindow?
    private var didResetCurrentReminder = false

    func show(tracker: ActivityTracker) {
        guard window == nil else { return }
        didResetCurrentReminder = false

        let resetAction: () -> Void = { [weak self, weak tracker] in
            guard let self, !self.didResetCurrentReminder else { return }
            self.didResetCurrentReminder = true
            tracker?.reset()
            NSSound.beep()
            self.hide()
        }

        let snoozeAction: (TimeInterval) -> Void = { [weak self, weak tracker] duration in
            tracker?.snoozeReminder(for: duration)
            self?.hide()
        }

        let screenFrame = (NSScreen.main ?? NSScreen.screens.first)?.frame ?? .zero
        let window = ReminderOverlayWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.onEscape = resetAction
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: ReminderOverlayView(
                onReset: resetAction,
                onSnooze: snoozeAction
            )
        )
        self.window = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hide() {
        window?.close()
        window = nil
    }
}

private final class ReminderOverlayWindow: NSWindow {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        if ReminderOverlayResetInput.isResetShortcut(keyCode: event.keyCode) {
            onEscape?()
            return
        }

        super.keyDown(with: event)
    }
}
