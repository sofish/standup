import Foundation
import Combine
import IOKit
import IOKit.pwr_mgt
import AppKit
import UserNotifications

public class ActivityTracker: ObservableObject {
    @Published public var activeSeconds: TimeInterval = 0
    @Published public var idleSeconds: TimeInterval = 0
    @Published public var isIdle: Bool = false
    @Published public var needsStandUp: Bool = false
    @Published public private(set) var snoozeUntil: Date?
    
    @Published public var targetActiveSeconds: TimeInterval = StandupTimingOptions.defaultTargetActiveSeconds
    public var idleThresholdSeconds: TimeInterval = 60

    public var hasScreenSession: Bool {
        activeSeconds > 0 || needsStandUp || snoozeUntil != nil
    }

    public var isQuietScreenSession: Bool {
        isIdle && hasScreenSession
    }
    
    private var timer: Timer?
    private var notificationObservers: [Any] = []
    
    private var isTesting: Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    // Injectable providers for testability
    private var systemIdleTimeProvider: () -> Double?
    private var displaySleepAssertionProvider: () -> Bool
    private var currentDateProvider: () -> Date
    
    public init(
        startTimer: Bool = true,
        systemIdleTimeProvider: @escaping () -> Double? = {
            var iterator: io_iterator_t = 0
            let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"), &iterator)
            guard result == kIOReturnSuccess else { return nil }
            defer { IOObjectRelease(iterator) }

            let service = IOIteratorNext(iterator)
            guard service != 0 else { return nil }
            defer { IOObjectRelease(service) }

            var dict: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &dict, kCFAllocatorDefault, 0) == kIOReturnSuccess,
                  let properties = dict?.takeRetainedValue() as? [String: Any],
                  let idleTimeNanoseconds = properties["HIDIdleTime"] as? Int64 else {
                return nil
            }

            return Double(idleTimeNanoseconds) / 1_000_000_000.0
        },
        displaySleepAssertionProvider: @escaping () -> Bool = {
            var assertionsStatus: Unmanaged<CFDictionary>?
            let result = IOPMCopyAssertionsStatus(&assertionsStatus)
            guard result == kIOReturnSuccess,
                  let status = assertionsStatus?.takeRetainedValue() as? [String: Any] else {
                return false
            }
            if let value = status["PreventUserIdleDisplaySleep"] as? Int {
                return value > 0
            }
            if let value = status["PreventUserIdleDisplaySleep"] as? NSNumber {
                return value.intValue > 0
            }
            return false
        },
        currentDateProvider: @escaping () -> Date = Date.init
    ) {
        self.systemIdleTimeProvider = systemIdleTimeProvider
        self.displaySleepAssertionProvider = displaySleepAssertionProvider
        self.currentDateProvider = currentDateProvider
        
        if startTimer {
            startTracking()
        }
        setupNotifications()
        requestNotificationPermission()
    }
    
    deinit {
        let nc = NSWorkspace.shared.notificationCenter
        for observer in notificationObservers {
            nc.removeObserver(observer)
        }
    }
    
    public func startTracking() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    public func reset() {
        activeSeconds = 0
        idleSeconds = 0
        isIdle = false
        needsStandUp = false
        snoozeUntil = nil
    }

    public func snoozeReminder(for duration: TimeInterval) {
        let duration = ReminderSnoozeOptions.normalizedDuration(duration)
        snoozeUntil = currentDateProvider().addingTimeInterval(duration)
        if needsStandUp {
            needsStandUp = false
        }
    }

    public func setTargetActiveSeconds(_ seconds: TimeInterval) {
        targetActiveSeconds = StandupTimingOptions.normalizedTargetActiveSeconds(seconds)
    }
    
    private func setupNotifications() {
        let nc = NSWorkspace.shared.notificationCenter
        
        let screenSleepObserver = nc.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            self?.reset()
        }
        let sessionResignObserver = nc.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.reset()
        }
        
        notificationObservers = [screenSleepObserver, sessionResignObserver]
    }
    
    public func tick() {
        let systemIdle = systemIdleTimeProvider() ?? 0

        let hasRecentInteraction = systemIdle < idleThresholdSeconds || displaySleepAssertionProvider()

        activeSeconds += 1

        if hasRecentInteraction {
            idleSeconds = 0
            isIdle = false
        } else {
            isIdle = true
            idleSeconds += 1
        }

        updateReminderStateIfNeeded()
    }

    private func updateReminderStateIfNeeded() {
        guard activeSeconds >= targetActiveSeconds else { return }

        if isReminderSnoozed() {
            if needsStandUp {
                needsStandUp = false
            }
        } else if !needsStandUp {
            needsStandUp = true
            triggerReminder()
        }
    }

    private func isReminderSnoozed() -> Bool {
        guard let snoozeUntil else { return false }

        if currentDateProvider() < snoozeUntil {
            return true
        }

        self.snoozeUntil = nil
        return false
    }
    
    private func triggerReminder() {
        guard !isTesting, Bundle.main.bundleIdentifier != nil else {
            print("🔔 Stand Up Reminder triggered! (Skipped native notification: Running under test or CLI)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "时间到啦，站起来动动！"
        content.body = "你已经连续活动了 1 小时。现在去倒杯水，休息 5 分钟吧！"
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "StandupReminder", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver notification: \(error)")
            }
        }
    }
    
    public func requestNotificationPermission() {
        guard !isTesting, Bundle.main.bundleIdentifier != nil else {
            print("Skipping notification permission request: Running under test or CLI")
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
}
