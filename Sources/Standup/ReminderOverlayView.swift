import SwiftUI
import StandupCore

struct ReminderOverlayView: View {
    @StateObject private var countdown = ReminderOverlayCountdown()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let onReset: () -> Void
    let onSnooze: (TimeInterval) -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            Color.black.opacity(ReminderOverlayMetrics.glassTintOpacity)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                AnimatedStandupIcon(dimension: CGFloat(ReminderOverlayMetrics.iconDimension))

                VStack(spacing: 8) {
                    Text("Time to stand up")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("Resetting in \(countdown.formattedRemaining)")
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Button(action: onReset) {
                    Label("Reset", systemImage: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal, 26)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(40)
            .foregroundStyle(.white)

            VStack {
                Spacer()
                ReminderLaterControls(onSnooze: onSnooze)
                    .padding(.bottom, CGFloat(ReminderOverlayMetrics.snoozeBottomPadding))
            }
            .padding(.horizontal, 40)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            countdown.reset()
        }
        .onReceive(timer) { _ in
            if countdown.tick() {
                onReset()
            }
        }
    }
}

private struct ReminderLaterControls: View {
    let onSnooze: (TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Label("Remind me later", systemImage: "clock")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .labelStyle(.titleAndIcon)
                .foregroundStyle(.white.opacity(ReminderOverlayMetrics.snoozeHeaderOpacity))

            HStack(spacing: 14) {
                ForEach(ReminderSnoozeOptions.durations, id: \.self) { duration in
                    Button(ReminderSnoozeOptions.label(for: duration)) {
                        onSnooze(duration)
                    }
                    .buttonStyle(GlassSnoozeButtonStyle())
                }
            }
        }
        .padding(.top, 2)
    }
}

private struct GlassSnoozeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(
                width: CGFloat(ReminderOverlayMetrics.snoozeButtonWidth),
                height: CGFloat(ReminderOverlayMetrics.snoozeButtonHeight)
            )
            .background {
                RoundedRectangle(
                    cornerRadius: CGFloat(ReminderOverlayMetrics.snoozeButtonCornerRadius),
                    style: .continuous
                )
                    .fill(Color.white.opacity(buttonFillOpacity(isPressed: configuration.isPressed)))
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: CGFloat(ReminderOverlayMetrics.snoozeButtonCornerRadius),
                    style: .continuous
                )
                    .stroke(Color.white.opacity(ReminderOverlayMetrics.snoozeButtonStrokeOpacity), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func buttonFillOpacity(isPressed: Bool) -> Double {
        isPressed
            ? ReminderOverlayMetrics.snoozeButtonPressedFillOpacity
            : ReminderOverlayMetrics.snoozeButtonFillOpacity
    }
}
