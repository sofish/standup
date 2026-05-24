import Foundation

public enum StandupTimingOptions {
    public static let defaultTargetActiveSeconds: TimeInterval = 60 * 60
    public static let defaultBreakThresholdSeconds: TimeInterval = 5 * 60

    public static let targetActiveSeconds: [TimeInterval] = [
        15 * 60,
        30 * 60,
        45 * 60,
        defaultTargetActiveSeconds,
        90 * 60,
        120 * 60
    ]

    public static let breakThresholdSeconds: [TimeInterval] = [
        60,
        3 * 60,
        defaultBreakThresholdSeconds,
        10 * 60,
        15 * 60
    ]

    public static func normalizedTargetActiveSeconds(_ seconds: TimeInterval) -> TimeInterval {
        targetActiveSeconds.contains(seconds) ? seconds : defaultTargetActiveSeconds
    }

    public static func normalizedBreakThresholdSeconds(_ seconds: TimeInterval) -> TimeInterval {
        breakThresholdSeconds.contains(seconds) ? seconds : defaultBreakThresholdSeconds
    }
}
