import Foundation

public enum ReminderSnoozeOptions {
    public static let durations: [TimeInterval] = [
        30 * 60,
        45 * 60,
        60 * 60,
        2 * 60 * 60
    ]

    public static let defaultDuration: TimeInterval = 30 * 60

    public static func normalizedDuration(_ duration: TimeInterval) -> TimeInterval {
        durations.contains(duration) ? duration : defaultDuration
    }

    public static func label(for duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours) hour \(remainingMinutes) min"
            }
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
        return "\(minutes) min"
    }
}
