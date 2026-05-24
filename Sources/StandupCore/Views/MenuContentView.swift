import SwiftUI
import AppKit

public struct MenuContentView: View {
    @ObservedObject var tracker: ActivityTracker
    @StateObject private var launchAtLogin = LaunchAtLoginController()
    @AppStorage("standup.targetActiveSeconds") private var selectedTargetActiveSeconds = StandupTimingOptions.defaultTargetActiveSeconds
    @AppStorage("standup.breakThresholdSeconds") private var selectedBreakThresholdSeconds = StandupTimingOptions.defaultBreakThresholdSeconds

    public init(tracker: ActivityTracker) {
        self.tracker = tracker
    }

    public var body: some View {
        VStack(spacing: 13) {
            header
            liquidDivider
            progressSection
            liquidDivider
            timingSection
            liquidDivider
            loginSection
            liquidDivider
            actionButtons
        }
        .padding(18)
        .frame(width: CGFloat(MenuDesignMetrics.width))
        .onAppear {
            applyTimingSettings()
            launchAtLogin.refresh()
        }
        .onChange(of: selectedTargetActiveSeconds) { targetActiveSeconds in
            applyTargetTime(targetActiveSeconds)
        }
        .onChange(of: selectedBreakThresholdSeconds) { breakThresholdSeconds in
            applyBreakTime(breakThresholdSeconds)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            LiquidIcon(systemName: tracker.isIdle ? "cup.and.saucer.fill" : "figure.stand")

            VStack(alignment: .leading, spacing: 2) {
                Text("Standup")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(statusDetail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            statusBadge
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(tracker.isIdle ? "Idle" : "Active")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(LiquidCapsuleBackground())
    }

    private var progressSection: some View {
        HStack(spacing: 14) {
            LiquidProgressRing(progress: progress, isIdle: tracker.isIdle)

            VStack(alignment: .leading, spacing: 5) {
                Label(tracker.isIdle ? "Break" : "Focus", systemImage: tracker.isIdle ? "clock.fill" : "timer")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)

                Text(displayTime)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)

                Text(tracker.isIdle ? "Reset at \(formatHourMinute(tracker.breakThresholdSeconds))" : "Goal \(formatHourMinute(tracker.targetActiveSeconds))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var timingSection: some View {
        VStack(spacing: 9) {
            timingMenuRow(
                title: "Target",
                systemName: "timer",
                selectedValue: tracker.targetActiveSeconds,
                options: StandupTimingOptions.targetActiveSeconds,
                onSelect: applyTargetTime
            )

            rowDivider

            timingMenuRow(
                title: "Break reset",
                systemName: "clock",
                selectedValue: tracker.breakThresholdSeconds,
                options: StandupTimingOptions.breakThresholdSeconds,
                onSelect: applyBreakTime
            )
        }
    }

    private var loginSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                LiquidIcon(systemName: "power")

                Text("Start at Login")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
                LiquidToggle(isOn: startAtLoginBinding)
            }

            if let errorMessage = launchAtLogin.errorMessage {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                tracker.reset()
            }) {
                Label("Reset Session", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LiquidButtonStyle(variant: .primary))

            HStack(spacing: 10) {
                Button(action: {
                    tracker.activeSeconds = max(0, tracker.targetActiveSeconds - 2)
                }) {
                    Label("Test", systemImage: "bell.badge")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidButtonStyle(variant: .secondary))

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label("Quit", systemImage: "power")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(LiquidButtonStyle(variant: .danger))
            }
        }
    }

    private var liquidDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.30))
            .frame(height: 1)
            .overlay(Rectangle().fill(.black.opacity(0.04)).offset(y: 1))
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(.white.opacity(0.24))
            .frame(height: 1)
            .padding(.leading, CGFloat(MenuDesignMetrics.iconTileSize) + 10)
    }

    private var statusColor: Color {
        tracker.isIdle ? .orange : .green
    }

    private var statusDetail: String {
        tracker.isIdle ? "Break timer is running" : "Active time is counting"
    }

    private var displayTime: String {
        if tracker.isIdle {
            return formatTime(tracker.breakThresholdSeconds - tracker.idleSeconds)
        }

        return formatTime(tracker.activeSeconds)
    }

    private var progress: Double {
        let total = tracker.isIdle ? tracker.breakThresholdSeconds : tracker.targetActiveSeconds
        let elapsed = tracker.isIdle ? tracker.idleSeconds : tracker.activeSeconds
        guard total > 0 else { return 0 }
        return min(max(Double(elapsed / total), 0), 1)
    }

    private var startAtLoginBinding: Binding<Bool> {
        Binding(
            get: {
                launchAtLogin.isEnabled
            },
            set: { enabled in
                launchAtLogin.setEnabled(enabled)
            }
        )
    }

    private func timingMenuRow(
        title: String,
        systemName: String,
        selectedValue: TimeInterval,
        options: [TimeInterval],
        onSelect: @escaping (TimeInterval) -> Void
    ) -> some View {
        HStack(spacing: 10) {
            LiquidIcon(systemName: systemName)

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()

            Menu {
                ForEach(options, id: \.self) { seconds in
                    Button(formatHourMinute(seconds)) {
                        onSelect(seconds)
                    }
                }
            } label: {
                HStack(spacing: 7) {
                    Text(formatHourMinute(selectedValue))
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
                .frame(width: 86, height: 30)
                .background(LiquidCapsuleBackground())
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
        }
    }

    private func applyTimingSettings() {
        applyTargetTime(selectedTargetActiveSeconds)
        applyBreakTime(selectedBreakThresholdSeconds)
    }

    private func applyTargetTime(_ seconds: TimeInterval) {
        let normalizedSeconds = StandupTimingOptions.normalizedTargetActiveSeconds(seconds)
        selectedTargetActiveSeconds = normalizedSeconds
        tracker.setTargetActiveSeconds(normalizedSeconds)
    }

    private func applyBreakTime(_ seconds: TimeInterval) {
        let normalizedSeconds = StandupTimingOptions.normalizedBreakThresholdSeconds(seconds)
        selectedBreakThresholdSeconds = normalizedSeconds
        tracker.setBreakThresholdSeconds(normalizedSeconds)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let secs = max(0, Int(seconds.rounded(.down)))
        let m = (secs % 3600) / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formatHourMinute(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins >= 60 {
            let hrs = mins / 60
            let remainingMins = mins % 60
            if remainingMins > 0 {
                return "\(hrs)h \(remainingMins)m"
            }
            return "\(hrs)h"
        }
        return "\(mins)m"
    }
}

private struct LiquidIcon: View {
    let systemName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.white.opacity(MenuDesignMetrics.crystalIconFillOpacity))
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(.white.opacity(MenuDesignMetrics.crystalIconStrokeOpacity), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(iconHighlight, lineWidth: 1)
                        .blendMode(.screen)
                )
                .shadow(color: .black.opacity(0.08), radius: 7, x: 0, y: 4)

            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(iconGradient)
        }
        .frame(
            width: CGFloat(MenuDesignMetrics.iconTileSize),
            height: CGFloat(MenuDesignMetrics.iconTileSize)
        )
    }

    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var iconHighlight: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.72), .white.opacity(0.12)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct LiquidCapsuleBackground: View {
    var body: some View {
        Capsule()
            .fill(.white.opacity(MenuDesignMetrics.crystalControlFillOpacity))
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                Capsule()
                    .stroke(.white.opacity(MenuDesignMetrics.crystalControlStrokeOpacity), lineWidth: 1)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.78), .white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .blendMode(.screen)
            )
            .shadow(color: .black.opacity(0.08), radius: 9, x: 0, y: 5)
    }
}

private struct LiquidButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case danger
    }

    let variant: Variant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.vertical, variant == .primary ? 11 : 9)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(
                    cornerRadius: CGFloat(MenuDesignMetrics.controlCornerRadius),
                    style: .continuous
                )
                .fill(fillColor(isPressed: configuration.isPressed))
                .overlay(
                    RoundedRectangle(
                        cornerRadius: CGFloat(MenuDesignMetrics.controlCornerRadius),
                        style: .continuous
                    )
                    .stroke(borderColor, lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(
                        cornerRadius: CGFloat(MenuDesignMetrics.controlCornerRadius),
                        style: .continuous
                    )
                    .stroke(highlightColor, lineWidth: 1)
                    .blendMode(.screen)
                )
                .shadow(color: shadowColor.opacity(configuration.isPressed ? 0.07 : 0.18), radius: configuration.isPressed ? 4 : 12, x: 0, y: configuration.isPressed ? 2 : 7)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func fillColor(isPressed: Bool) -> Color {
        switch variant {
        case .primary:
            return .black.opacity(isPressed ? 0.76 : 0.88)
        case .secondary:
            return .white.opacity(isPressed ? 0.32 : 0.42)
        case .danger:
            return .red.opacity(isPressed ? 0.12 : 0.16)
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .danger:
            return .red
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return .white.opacity(0.24)
        case .secondary:
            return .white.opacity(0.56)
        case .danger:
            return .red.opacity(0.22)
        }
    }

    private var highlightColor: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.62), .white.opacity(0.10)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var shadowColor: Color {
        switch variant {
        case .primary:
            return .black
        case .secondary:
            return .black.opacity(0.45)
        case .danger:
            return .red
        }
    }
}

private struct LiquidProgressRing: View {
    let progress: Double
    let isIdle: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.28), lineWidth: 7)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1)))
                .stroke(
                    progressGradient,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(0.42), radius: 6, x: 0, y: 3)
                .animation(.easeInOut(duration: 0.24), value: progress)
        }
        .frame(
            width: CGFloat(MenuDesignMetrics.progressSize),
            height: CGFloat(MenuDesignMetrics.progressSize)
        )
    }

    private var progressColor: Color {
        isIdle ? .orange : .green
    }

    private var progressGradient: LinearGradient {
        if isIdle {
            return LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
        }

        return LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
    }
}

private struct LiquidToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
                isOn.toggle()
            }
        }) {
            Capsule()
                .fill(isOn ? Color.green.opacity(0.92) : Color.white.opacity(0.38))
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.54), lineWidth: 1)
                )
                .frame(width: 46, height: 24)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.94))
                        .shadow(color: .black.opacity(0.18), radius: 4, x: 0, y: 2)
                        .frame(width: 18, height: 18)
                        .offset(x: isOn ? 10 : -10)
                )
        }
        .buttonStyle(.plain)
    }
}
