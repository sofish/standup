import Foundation
import Combine

public enum ReminderOverlayMetrics {
    public static let autoResetSeconds: TimeInterval = 5 * 60
    public static let iconDimension: Double = 104
    public static let glassTintOpacity: Double = 0.22
    public static let snoozeHeaderOpacity: Double = 0.94
    public static let snoozeButtonFillOpacity: Double = 0.12
    public static let snoozeButtonStrokeOpacity: Double = 0.34
    public static let snoozeButtonPressedFillOpacity: Double = 0.26
    public static let snoozeButtonWidth: Double = 104
    public static let snoozeButtonHeight: Double = 42
    public static let snoozeButtonCornerRadius: Double = 16
    public static let snoozeBottomPadding: Double = 56
}

public enum ReminderOverlayResetInput {
    public static let escapeKeyCode: UInt16 = 53

    public static func isResetShortcut(keyCode: UInt16) -> Bool {
        keyCode == escapeKeyCode
    }
}

public final class ReminderOverlayCountdown: ObservableObject {
    public let durationSeconds: TimeInterval
    @Published public private(set) var remainingSeconds: TimeInterval

    public init(durationSeconds: TimeInterval = ReminderOverlayMetrics.autoResetSeconds) {
        let durationSeconds = max(0, durationSeconds)
        self.durationSeconds = durationSeconds
        self.remainingSeconds = durationSeconds
    }

    public func reset() {
        remainingSeconds = durationSeconds
    }

    @discardableResult
    public func tick() -> Bool {
        guard remainingSeconds > 0 else { return false }
        remainingSeconds = max(0, remainingSeconds - 1)
        return remainingSeconds == 0
    }

    public var formattedRemaining: String {
        let seconds = Int(remainingSeconds.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
