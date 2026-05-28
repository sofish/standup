import XCTest
import AppKit
@testable import StandupCore

final class StandupTests: XCTestCase {

    func testMenuBarIconRendersSmallerThanSourceAsset() {
        XCTAssertLessThan(MenuBarIconMetrics.renderedDimension, MenuBarIconMetrics.assetDimension)
        XCTAssertLessThan(MenuBarIconMetrics.renderedDimension, MenuBarIconMetrics.statusAssetDimension)
        XCTAssertEqual(MenuBarIconMetrics.renderedDimension, 18)
        XCTAssertEqual(MenuBarIconMetrics.statusAssetDimension, 288)
        XCTAssertGreaterThan(MenuBarIconMetrics.renderedDimension, 0)
    }

    func testMenuBarIconAnimationUsesSmoothFrameTiming() {
        XCTAssertEqual(MenuBarIconMetrics.animationFrameCount, 16)
        XCTAssertEqual(MenuBarIconMetrics.animationFrameInterval, 0.12)
        let loopDuration = Double(MenuBarIconMetrics.animationFrameCount) * MenuBarIconMetrics.animationFrameInterval
        XCTAssertGreaterThanOrEqual(loopDuration, 1.8)
        XCTAssertLessThanOrEqual(loopDuration, 2.2)
    }

    func testGeneratedAnimationFrameResourcesMatchRuntimeCount() {
        let fileManager = FileManager.default
        let resourceDirectory = "Resources"
        let frameResources = (try? fileManager.contentsOfDirectory(atPath: resourceDirectory))?
            .filter { $0.hasPrefix("standup_") && $0.hasSuffix(".png") } ?? []

        XCTAssertEqual(frameResources.count, MenuBarIconMetrics.animationFrameCount)
        for frameIndex in 0..<MenuBarIconMetrics.animationFrameCount {
            let path = "\(resourceDirectory)/standup_\(frameIndex).png"
            XCTAssertTrue(fileManager.fileExists(atPath: path), "Missing generated frame at \(path)")
        }
    }

    func testGeneratedAnimationFramesUseHighResolutionAssets() throws {
        let resourceDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources")

        for frameIndex in 0..<MenuBarIconMetrics.animationFrameCount {
            let imageURL = resourceDirectory.appendingPathComponent("standup_\(frameIndex).png")
            let imageData = try Data(contentsOf: imageURL)
            guard let representation = NSBitmapImageRep(data: imageData) else {
                XCTFail("Unable to read generated frame at \(imageURL.path)")
                continue
            }
            XCTAssertEqual(representation.pixelsWide, Int(MenuBarIconMetrics.assetDimension))
            XCTAssertEqual(representation.pixelsHigh, Int(MenuBarIconMetrics.assetDimension))
        }
    }

    func testGeneratedApplicationIconResourcesExist() throws {
        let resourceDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources")
        let appIconURL = resourceDirectory.appendingPathComponent("AppIcon.png")
        let icnsURL = resourceDirectory.appendingPathComponent("AppIcon.icns")

        let imageData = try Data(contentsOf: appIconURL)
        let representation = try XCTUnwrap(NSBitmapImageRep(data: imageData))

        XCTAssertEqual(representation.pixelsWide, Int(MenuBarIconMetrics.appIconDimension))
        XCTAssertEqual(representation.pixelsHigh, Int(MenuBarIconMetrics.appIconDimension))
        XCTAssertTrue(FileManager.default.fileExists(atPath: icnsURL.path))
    }

    func testMenuBarCatDeskResourcesUseHighResolutionAssets() throws {
        let resourceDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources")

        for fileName in ["MenuBarCatDesk.png", "MenuBarCatDeskSparkle.png"] {
            let imageURL = resourceDirectory.appendingPathComponent(fileName)
            let imageData = try Data(contentsOf: imageURL)
            let representation = try XCTUnwrap(NSBitmapImageRep(data: imageData))

            XCTAssertEqual(representation.pixelsWide, Int(MenuBarIconMetrics.statusAssetDimension))
            XCTAssertEqual(representation.pixelsHigh, Int(MenuBarIconMetrics.statusAssetDimension))
        }
    }

    func testBuildScriptDeclaresApplicationIcon() throws {
        let buildScriptURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("build.sh")
        let buildScript = try String(contentsOf: buildScriptURL, encoding: .utf8)

        XCTAssertTrue(buildScript.contains("<key>CFBundleIconFile</key>"))
        XCTAssertTrue(buildScript.contains("<string>AppIcon.icns</string>"))
        XCTAssertTrue(buildScript.contains("<key>CFBundleShortVersionString</key>"))
        XCTAssertTrue(buildScript.contains("<string>1.0.3</string>"))
        XCTAssertTrue(buildScript.contains("<key>CFBundleVersion</key>"))
        XCTAssertTrue(buildScript.contains("<string>4</string>"))
    }

    func testGeneratedAnimationUsesSequenceEndpoints() {
        XCTAssertEqual(MenuBarIconMetrics.sittingFrameIndex, 0)
        XCTAssertEqual(MenuBarIconMetrics.standingFrameIndex, MenuBarIconMetrics.animationFrameCount - 1)
    }

    func testMenuDesignMetricsUseSoftCompactDropdownScale() {
        XCTAssertEqual(MenuDesignMetrics.width, 268)
        XCTAssertGreaterThan(MenuDesignMetrics.iconTileSize, MenuBarIconMetrics.renderedDimension)
        XCTAssertLessThanOrEqual(MenuDesignMetrics.progressSize, 90)
    }

    func testLiquidGlassMenuUsesNativePanelMetrics() {
        XCTAssertEqual(MenuDesignMetrics.controlCornerRadius, 20)
        XCTAssertEqual(MenuDesignMetrics.iconTileSize, 30)
        XCTAssertGreaterThanOrEqual(MenuDesignMetrics.crystalControlFillOpacity, 0.40)
        XCTAssertGreaterThan(MenuDesignMetrics.crystalControlStrokeOpacity, MenuDesignMetrics.crystalControlFillOpacity)
        XCTAssertLessThan(MenuDesignMetrics.crystalIconFillOpacity, MenuDesignMetrics.crystalControlFillOpacity)
        XCTAssertGreaterThanOrEqual(MenuDesignMetrics.crystalIconStrokeOpacity, 0.60)
    }

    func testActivityTrackerUsesDefaultTimingOptions() {
        let tracker = makeTracker()

        XCTAssertEqual(tracker.targetActiveSeconds, StandupTimingOptions.defaultTargetActiveSeconds)
    }

    func testActivityTrackerAppliesTimingSelectionsImmediately() {
        let tracker = makeTracker()

        tracker.setTargetActiveSeconds(30 * 60)

        XCTAssertEqual(tracker.targetActiveSeconds, 30 * 60)
    }

    func testActivityTrackerNormalizesUnsupportedTimingSelections() {
        let tracker = makeTracker()

        tracker.setTargetActiveSeconds(17)

        XCTAssertEqual(tracker.targetActiveSeconds, StandupTimingOptions.defaultTargetActiveSeconds)
    }

    func testTimingOptionsNormalizeUnsupportedSelections() {
        XCTAssertEqual(
            StandupTimingOptions.normalizedTargetActiveSeconds(17),
            StandupTimingOptions.defaultTargetActiveSeconds
        )
        XCTAssertEqual(StandupTimingOptions.normalizedTargetActiveSeconds(30 * 60), 30 * 60)
    }

    func testReminderOverlayCountdownDefaultsToFiveMinuteAutoReset() {
        let countdown = ReminderOverlayCountdown()

        XCTAssertEqual(countdown.durationSeconds, 5 * 60)
        XCTAssertEqual(countdown.remainingSeconds, 5 * 60)
        XCTAssertEqual(countdown.formattedRemaining, "5:00")
    }

    func testReminderSnoozeOptionsExposeExpectedDurations() {
        XCTAssertEqual(ReminderSnoozeOptions.durations, [
            TimeInterval(30 * 60),
            TimeInterval(45 * 60),
            TimeInterval(60 * 60),
            TimeInterval(2 * 60 * 60)
        ])
        XCTAssertEqual(ReminderSnoozeOptions.normalizedDuration(17), 30 * 60)
        XCTAssertEqual(ReminderSnoozeOptions.label(for: 30 * 60), "30 min")
        XCTAssertEqual(ReminderSnoozeOptions.label(for: 45 * 60), "45 min")
        XCTAssertEqual(ReminderSnoozeOptions.label(for: 60 * 60), "1 hour")
        XCTAssertEqual(ReminderSnoozeOptions.label(for: 2 * 60 * 60), "2 hours")
    }

    func testReminderOverlayUsesGlassTintInsteadOfOpaqueScrim() {
        XCTAssertGreaterThan(ReminderOverlayMetrics.glassTintOpacity, 0)
        XCTAssertLessThan(ReminderOverlayMetrics.glassTintOpacity, 0.35)
    }

    func testReminderOverlaySnoozeControlsUseClearGlassMetrics() {
        XCTAssertGreaterThan(ReminderOverlayMetrics.snoozeHeaderOpacity, 0.85)
        XCTAssertLessThanOrEqual(ReminderOverlayMetrics.snoozeHeaderOpacity, 1)
        XCTAssertGreaterThan(ReminderOverlayMetrics.snoozeButtonFillOpacity, 0)
        XCTAssertLessThan(ReminderOverlayMetrics.snoozeButtonFillOpacity, ReminderOverlayMetrics.snoozeButtonStrokeOpacity)
        XCTAssertGreaterThan(
            ReminderOverlayMetrics.snoozeButtonPressedFillOpacity,
            ReminderOverlayMetrics.snoozeButtonFillOpacity
        )
        XCTAssertEqual(ReminderOverlayMetrics.snoozeButtonWidth, 104)
        XCTAssertEqual(ReminderOverlayMetrics.snoozeButtonHeight, 42)
        XCTAssertEqual(ReminderOverlayMetrics.snoozeButtonCornerRadius, 16)
        XCTAssertEqual(ReminderOverlayMetrics.snoozeBottomPadding, 56)
    }

    func testReminderOverlayCountdownCompletesOnceAtZero() {
        let countdown = ReminderOverlayCountdown(durationSeconds: 3)

        XCTAssertFalse(countdown.tick())
        XCTAssertEqual(countdown.formattedRemaining, "0:02")
        XCTAssertFalse(countdown.tick())
        XCTAssertTrue(countdown.tick())
        XCTAssertEqual(countdown.remainingSeconds, 0)
        XCTAssertFalse(countdown.tick())
    }

    func testReminderOverlayEscapeKeyIsResetShortcut() {
        XCTAssertTrue(ReminderOverlayResetInput.isResetShortcut(keyCode: ReminderOverlayResetInput.escapeKeyCode))
        XCTAssertFalse(ReminderOverlayResetInput.isResetShortcut(keyCode: 36))
    }

    @MainActor
    func testLaunchAtLoginControllerReflectsServiceChanges() {
        let service = MockLaunchAtLoginService(isEnabled: false)
        let controller = LaunchAtLoginController(service: service)

        XCTAssertFalse(controller.isEnabled)

        controller.setEnabled(true)

        XCTAssertEqual(service.requestedStates, [true])
        XCTAssertTrue(controller.isEnabled)
        XCTAssertNil(controller.errorMessage)

        controller.setEnabled(false)

        XCTAssertEqual(service.requestedStates, [true, false])
        XCTAssertFalse(controller.isEnabled)
        XCTAssertNil(controller.errorMessage)
    }

    @MainActor
    func testLaunchAtLoginControllerReportsFailureWithoutFlippingState() {
        let service = MockLaunchAtLoginService(isEnabled: false, error: MockLaunchAtLoginError())
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        XCTAssertEqual(service.requestedStates, [true])
        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(controller.errorMessage, "Login item unavailable")
    }

    @MainActor
    func testLaunchAtLoginControllerSkipsServiceWhenStateAlreadyMatches() {
        let service = MockLaunchAtLoginService(isEnabled: true)
        let controller = LaunchAtLoginController(service: service)

        controller.setEnabled(true)

        XCTAssertTrue(controller.isEnabled)
        XCTAssertTrue(service.requestedStates.isEmpty)
        XCTAssertNil(controller.errorMessage)
    }
    
    func testUserActiveAccruesTime() {
        // Given
        let tracker = makeTracker(idleTime: 0.0)
        tracker.idleThresholdSeconds = 10
        
        // When: User is active (idle time = 0 < threshold)
        tracker.tick()
        
        // Then
        XCTAssertEqual(tracker.activeSeconds, 1)
        XCTAssertEqual(tracker.idleSeconds, 0)
        XCTAssertFalse(tracker.isIdle)
    }
    
    func testQuietInputKeepsAccruingScreenTime() {
        // Given
        let tracker = makeTracker(idleTime: 20.0)
        tracker.idleThresholdSeconds = 10
        tracker.activeSeconds = 100 // Start with some active time
        
        // When: User is idle
        tracker.tick()
        
        // Then
        XCTAssertEqual(tracker.activeSeconds, 101)
        XCTAssertEqual(tracker.idleSeconds, 1)
        XCTAssertTrue(tracker.isIdle)
        XCTAssertTrue(tracker.hasScreenSession)
        XCTAssertTrue(tracker.isQuietScreenSession)
    }

    func testAwakeScreenTimeStartsSessionEvenWithoutRecentInput() {
        let tracker = makeTracker(idleTime: 20.0)
        tracker.idleThresholdSeconds = 10

        tracker.tick()

        XCTAssertEqual(tracker.activeSeconds, 1)
        XCTAssertEqual(tracker.idleSeconds, 1)
        XCTAssertTrue(tracker.isIdle)
        XCTAssertTrue(tracker.hasScreenSession)
        XCTAssertTrue(tracker.isQuietScreenSession)
    }
    
    func testMediaPlaybackKeepsUserActive() {
        // Given
        let tracker = makeTracker(idleTime: 20.0, displaySleepAssertion: true)
        tracker.idleThresholdSeconds = 10
        
        // When
        tracker.tick()
        
        // Then
        XCTAssertEqual(tracker.activeSeconds, 1)
        XCTAssertEqual(tracker.idleSeconds, 0)
        XCTAssertFalse(tracker.isIdle)
        XCTAssertTrue(tracker.hasScreenSession)
        XCTAssertFalse(tracker.isQuietScreenSession)
    }
    
    func testLongQuietInputDoesNotResetAwakeScreenSession() {
        // Given
        let tracker = makeTracker(idleTime: 20.0)
        tracker.idleThresholdSeconds = 10
        tracker.activeSeconds = 500
        
        // When: Idle for 1 tick
        tracker.tick()
        XCTAssertEqual(tracker.activeSeconds, 501)
        XCTAssertEqual(tracker.idleSeconds, 1)
        
        // Idle for 2nd tick
        tracker.tick()
        XCTAssertEqual(tracker.activeSeconds, 502)
        XCTAssertEqual(tracker.idleSeconds, 2)
        
        // Idle for 3rd tick; screen time still counts while the display is awake.
        tracker.tick()
        
        // Then
        XCTAssertEqual(tracker.activeSeconds, 503)
        XCTAssertEqual(tracker.idleSeconds, 3)
        XCTAssertTrue(tracker.isIdle)
        XCTAssertTrue(tracker.isQuietScreenSession)
    }

    func testQuietInputDoesNotClearReminderState() {
        // Given
        let tracker = makeTracker(idleTime: 20.0)
        tracker.idleThresholdSeconds = 10
        tracker.activeSeconds = 500
        tracker.needsStandUp = true

        // When: User is quiet at the keyboard while the screen stays awake
        tracker.tick()
        tracker.tick()

        // Then
        XCTAssertEqual(tracker.activeSeconds, 502)
        XCTAssertEqual(tracker.idleSeconds, 2)
        XCTAssertTrue(tracker.isIdle)
        XCTAssertTrue(tracker.needsStandUp)
    }

    func testManualResetClearsReminderState() {
        // Given
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let tracker = makeTracker(currentDateProvider: { currentDate })
        tracker.activeSeconds = 500
        tracker.idleSeconds = 12
        tracker.isIdle = true
        tracker.needsStandUp = true
        tracker.snoozeReminder(for: 30 * 60)
        currentDate = currentDate.addingTimeInterval(1)

        // When
        tracker.reset()

        // Then
        XCTAssertEqual(tracker.activeSeconds, 0)
        XCTAssertEqual(tracker.idleSeconds, 0)
        XCTAssertFalse(tracker.isIdle)
        XCTAssertFalse(tracker.needsStandUp)
        XCTAssertNil(tracker.snoozeUntil)
    }

    func testScreenLockResetsAndPausesTickCounting() {
        let log = CapturingDebugLog()
        let tracker = makeTracker(idleTime: 0.0, debugLog: log)
        tracker.activeSeconds = 500
        tracker.idleSeconds = 20
        tracker.needsStandUp = true

        tracker.handleScreenLocked()
        tracker.tick()

        XCTAssertEqual(tracker.activeSeconds, 0)
        XCTAssertEqual(tracker.idleSeconds, 0)
        XCTAssertFalse(tracker.needsStandUp)
        XCTAssertTrue(log.messages.contains { $0.contains("reset reason=screen_locked") })
        XCTAssertFalse(log.messages.contains { $0.contains("screen.progress") })
    }

    func testScreenUnlockResetsEvenIfLockNotificationWasMissed() {
        let log = CapturingDebugLog()
        let tracker = makeTracker(idleTime: 0.0, debugLog: log)
        tracker.activeSeconds = 48 * 60
        tracker.idleSeconds = 48 * 60

        tracker.handleScreenUnlocked()

        XCTAssertEqual(tracker.activeSeconds, 0)
        XCTAssertEqual(tracker.idleSeconds, 0)
        XCTAssertFalse(tracker.isIdle)
        XCTAssertTrue(log.messages.contains { $0.contains("reset reason=screen_unlocked") })
    }
    
    func testReachingTargetTimeTriggersRemindingState() {
        // Given
        let tracker = makeTracker(idleTime: 0.0)
        tracker.targetActiveSeconds = 5
        tracker.activeSeconds = 4
        
        // When: User is active and ticks past target
        tracker.tick()
        
        // Then: Should enter needsStandUp and not reset activeSeconds immediately
        XCTAssertTrue(tracker.needsStandUp)
        XCTAssertEqual(tracker.activeSeconds, 5)
        
        // Next tick: remains active, activeSeconds continues to accrue
        tracker.tick()
        XCTAssertTrue(tracker.needsStandUp)
        XCTAssertEqual(tracker.activeSeconds, 6)
    }

    func testQuietInputCanStillReachReminderTarget() {
        let tracker = makeTracker(idleTime: 20.0)
        tracker.idleThresholdSeconds = 10
        tracker.targetActiveSeconds = 5
        tracker.activeSeconds = 4

        tracker.tick()

        XCTAssertTrue(tracker.isIdle)
        XCTAssertEqual(tracker.idleSeconds, 1)
        XCTAssertEqual(tracker.activeSeconds, 5)
        XCTAssertTrue(tracker.needsStandUp)
        XCTAssertTrue(tracker.hasScreenSession)
        XCTAssertTrue(tracker.isQuietScreenSession)
    }

    func testActivityTrackerWritesLocalDebugEvents() {
        let log = CapturingDebugLog()
        let tracker = makeTracker(idleTime: 20.0, debugLog: log)
        tracker.idleThresholdSeconds = 10
        tracker.targetActiveSeconds = 2

        tracker.tick()
        tracker.tick()
        tracker.reset()

        XCTAssertTrue(log.messages.contains { $0.contains("tracker.started") })
        XCTAssertTrue(log.messages.contains { $0.contains("screen.quiet") && $0.contains("active=1") && $0.contains("locked=false") })
        XCTAssertTrue(log.messages.contains { $0.contains("reminder.triggered") && $0.contains("active=2") && $0.contains("locked=false") })
        XCTAssertTrue(log.messages.contains { $0.contains("reset reason=manual") && $0.contains("active=2") && $0.contains("locked=false") })
    }

    func testLocalDebugLogWritesAndRotatesConfiguredFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("StandupDebugLogTests-\(UUID().uuidString)")
        let fileURL = directory.appendingPathComponent("standup.log")
        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let log = LocalDebugLog(
            fileURL: fileURL,
            maxBytes: 20,
            dateProvider: { Date(timeIntervalSince1970: 1_800_000_000) }
        )

        log.write("first entry")
        log.write("second entry")

        let rotatedURL = fileURL.deletingPathExtension().appendingPathExtension("log.1")
        let currentContent = try String(contentsOf: fileURL, encoding: .utf8)
        let rotatedContent = try String(contentsOf: rotatedURL, encoding: .utf8)

        XCTAssertTrue(currentContent.contains("second entry"))
        XCTAssertTrue(rotatedContent.contains("first entry"))
        XCTAssertTrue(currentContent.contains("2027"))
    }

    func testSnoozeSuppressesReminderWithoutResettingActiveTime() {
        // Given
        var currentDate = Date(timeIntervalSince1970: 1_000)
        let tracker = makeTracker(idleTime: 0.0, currentDateProvider: { currentDate })
        tracker.targetActiveSeconds = 5
        tracker.activeSeconds = 5
        tracker.needsStandUp = true

        // When
        tracker.snoozeReminder(for: 30 * 60)

        // Then: snooze hides the reminder without pretending the user stood up.
        XCTAssertFalse(tracker.needsStandUp)
        XCTAssertEqual(tracker.activeSeconds, 5)
        XCTAssertEqual(tracker.snoozeUntil, currentDate.addingTimeInterval(30 * 60))

        tracker.tick()
        XCTAssertFalse(tracker.needsStandUp)
        XCTAssertEqual(tracker.activeSeconds, 6)

        currentDate = currentDate.addingTimeInterval(30 * 60 + 1)
        tracker.tick()
        XCTAssertTrue(tracker.needsStandUp)
        XCTAssertNil(tracker.snoozeUntil)
        XCTAssertEqual(tracker.activeSeconds, 7)
    }

    func testOpenSourceFilesDeclareMitLicenseAndSecurityPolicy() throws {
        let license = try projectFile("LICENSE")
        XCTAssertTrue(license.contains("MIT License"))
        XCTAssertTrue(license.contains("Copyright (c) 2026 Standup contributors"))
        XCTAssertTrue(license.contains("Permission is hereby granted, free of charge"))
        XCTAssertTrue(license.contains("THE SOFTWARE IS PROVIDED \"AS IS\""))

        let security = try projectFile("SECURITY.md")
        XCTAssertTrue(security.contains("GitHub Security Advisories"))
        XCTAssertTrue(security.contains("Please do not file public issues"))
        XCTAssertTrue(security.contains("No app network client"))
        XCTAssertTrue(security.contains("SMAppService.mainApp"))
        XCTAssertTrue(security.contains("1.0.x"))

        let contributing = try projectFile("CONTRIBUTING.md")
        XCTAssertTrue(contributing.contains("swift test"))
        XCTAssertTrue(contributing.contains("./build.sh"))
        XCTAssertTrue(contributing.contains("Document the provenance and license of any new image"))
    }

    func testReadmeLinksOpenSourceAndSecurityDocs() throws {
        let readme = try projectFile("README.md")

        XCTAssertTrue(readme.contains("Standup is local-only"))
        XCTAssertTrue(readme.contains("continuous screen-session time"))
        XCTAssertTrue(readme.contains("keeps counting while the user session stays awake"))
        XCTAssertTrue(readme.contains("sudo xattr -dr com.apple.quarantine /Applications/Standup.app"))
        XCTAssertTrue(readme.contains("not Developer ID signed or notarized"))
        XCTAssertTrue(readme.contains("[SECURITY.md](SECURITY.md)"))
        XCTAssertTrue(readme.contains("[docs/security.md](docs/security.md)"))
        XCTAssertTrue(readme.contains("[CONTRIBUTING.md](CONTRIBUTING.md)"))
        XCTAssertTrue(readme.contains("[MIT License](LICENSE)"))
    }

    func testOpenSourceDocsAndGitIgnoreCoverReleaseRisks() throws {
        let openSourceDoc = try projectFile("docs/open_source.md")
        XCTAssertTrue(openSourceDoc.contains("MIT License"))
        XCTAssertTrue(openSourceDoc.contains("generated image and icon assets"))
        XCTAssertTrue(openSourceDoc.contains("GitHub Security Advisories"))

        let securityDoc = try projectFile("docs/security.md")
        XCTAssertTrue(securityDoc.contains("Local-Only Boundary"))
        XCTAssertTrue(securityDoc.contains("No app network client"))
        XCTAssertTrue(securityDoc.contains("standup.log"))
        XCTAssertTrue(securityDoc.contains("Sign and notarize public binary builds"))
        XCTAssertTrue(securityDoc.contains("ad-hoc signed development zip archives"))
        XCTAssertTrue(securityDoc.contains("xattr"))
        XCTAssertTrue(securityDoc.contains("checksum verification"))

        let gitignore = try projectFile(".gitignore")
        XCTAssertTrue(gitignore.contains(".build/"))
        XCTAssertTrue(gitignore.contains("build/"))
        XCTAssertTrue(gitignore.contains("*.app"))
        XCTAssertTrue(gitignore.contains("*.zip"))
        XCTAssertTrue(gitignore.contains(".DS_Store"))
    }

    func testSecurityDocumentationMatchesCurrentNoNetworkBoundary() throws {
        let sourceText = try allSwiftSourceText()
        XCTAssertFalse(sourceText.contains("URLSession"))
        XCTAssertFalse(sourceText.contains("import Network"))
        XCTAssertFalse(sourceText.contains("NWConnection"))
        XCTAssertFalse(sourceText.contains("http://"))
        XCTAssertFalse(sourceText.contains("https://"))
    }

    func testPublicDocumentationDoesNotExposeLocalMachinePaths() throws {
        for path in [
            "README.md",
            "SECURITY.md",
            "CONTRIBUTING.md",
            "docs/architecture.md",
            "docs/implementation_plan.md",
            "docs/open_source.md",
            "docs/security.md"
        ] {
            let content = try projectFile(path)
            XCTAssertFalse(content.contains("/Users/"), "\(path) contains an absolute user path")
            XCTAssertFalse(content.contains("sofish"), "\(path) contains a local username")
            XCTAssertFalse(content.contains(".codex"), "\(path) contains a local tool cache path")
        }
    }

    private func makeTracker(
        idleTime: Double? = 0.0,
        displaySleepAssertion: Bool = false,
        currentDateProvider: @escaping () -> Date = Date.init,
        debugLog: LocalDebugLogging? = nil
    ) -> ActivityTracker {
        ActivityTracker(
            startTimer: false,
            systemIdleTimeProvider: { idleTime },
            displaySleepAssertionProvider: { displaySleepAssertion },
            currentDateProvider: currentDateProvider,
            debugLog: debugLog
        )
    }

    private func projectFile(_ path: String) throws -> String {
        let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(path)
        return try String(contentsOf: url, encoding: .utf8)
    }

    private func allSwiftSourceText() throws -> String {
        let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources")
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil
        ) else {
            XCTFail("Unable to enumerate Swift sources")
            return ""
        }

        var sourceText = ""
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            sourceText += try String(contentsOf: url, encoding: .utf8)
        }
        return sourceText
    }
}

private final class MockLaunchAtLoginService: LaunchAtLoginService {
    var isEnabled: Bool
    var requestedStates: [Bool] = []

    private let error: Error?

    init(isEnabled: Bool, error: Error? = nil) {
        self.isEnabled = isEnabled
        self.error = error
    }

    func setEnabled(_ enabled: Bool) throws {
        requestedStates.append(enabled)

        if let error {
            throw error
        }

        isEnabled = enabled
    }
}

private final class CapturingDebugLog: LocalDebugLogging {
    var messages: [String] = []

    func write(_ message: String) {
        messages.append(message)
    }
}

private struct MockLaunchAtLoginError: LocalizedError {
    var errorDescription: String? {
        "Login item unavailable"
    }
}
