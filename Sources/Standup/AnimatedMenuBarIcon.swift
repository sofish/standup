import SwiftUI
import AppKit
import StandupCore

public struct AnimatedMenuBarIcon: View {
    @ObservedObject var tracker: ActivityTracker
    
    public init(tracker: ActivityTracker) {
        self.tracker = tracker
    }
    
    public var body: some View {
        if tracker.needsStandUp {
            AnimatingIconView()
        } else {
            StaticIconView(isIdle: tracker.isIdle)
        }
    }
}

struct AnimatedStandupIcon: View {
    @State private var currentFrame = 0
    let dimension: CGFloat
    private let timer = Timer.publish(
        every: MenuBarIconMetrics.animationFrameInterval,
        on: .main,
        in: .common
    ).autoconnect()
    
    var body: some View {
        StandupIconImage(frameIndex: currentFrame, dimension: dimension)
        .transaction { transaction in
            transaction.animation = nil
        }
        .onReceive(timer) { _ in
            currentFrame = (currentFrame + 1) % MenuBarIconMetrics.animationFrameCount
        }
    }
}

private struct StaticIconView: View {
    let isIdle: Bool
    
    var body: some View {
        let frameIndex = isIdle ? MenuBarIconMetrics.standingFrameIndex : MenuBarIconMetrics.sittingFrameIndex
        MenuBarCatWorkstationIcon(frameIndex: frameIndex)
    }
}

private struct AnimatingIconView: View {
    @State private var currentFrame = 0
    private let timer = Timer.publish(
        every: MenuBarIconMetrics.animationFrameInterval,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        MenuBarCatWorkstationIcon(frameIndex: currentFrame)
            .transaction { transaction in
                transaction.animation = nil
            }
            .onReceive(timer) { _ in
                currentFrame = (currentFrame + 1) % MenuBarIconMetrics.animationFrameCount
            }
    }
}

private struct MenuBarCatWorkstationIcon: View {
    let frameIndex: Int

    var body: some View {
        Group {
            if let image = MenuBarCatDeskCache.image(sparkle: shouldDrawSparkle) {
                Image(nsImage: image)
                    .resizable()
            } else {
                Image(systemName: "display")
                    .resizable()
                    .foregroundStyle(.primary)
            }
        }
        .scaledToFit()
        .frame(
            width: CGFloat(MenuBarIconMetrics.renderedDimension),
            height: CGFloat(MenuBarIconMetrics.renderedDimension)
        )
    }

    private var shouldDrawSparkle: Bool {
        frameIndex >= 8 && frameIndex % 2 == 0
    }
}

private enum MenuBarCatDeskCache {
    static let normal = loadImage(named: "MenuBarCatDesk")
    static let sparkle = loadImage(named: "MenuBarCatDeskSparkle")

    static func image(sparkle: Bool) -> NSImage? {
        sparkle ? self.sparkle : normal
    }

    private static func loadImage(named name: String) -> NSImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "png"),
              let image = NSImage(contentsOfFile: path) else {
            return nil
        }
        image.isTemplate = true
        image.size = NSSize(
            width: MenuBarIconMetrics.renderedDimension,
            height: MenuBarIconMetrics.renderedDimension
        )
        return image
    }
}

private struct StandupIconImage: View {
    let frameIndex: Int
    let dimension: CGFloat
    
    var body: some View {
        Group {
            if let image = loadFrame(frameIndex) {
                Image(nsImage: image)
                    .resizable()
            } else {
                Image(systemName: fallbackSymbol(for: frameIndex))
                    .resizable()
            }
        }
        .scaledToFit()
        .frame(width: dimension, height: dimension)
    }
}

private func loadFrame(_ index: Int) -> NSImage? {
    guard IconFrameCache.frames.indices.contains(index) else { return nil }
    return IconFrameCache.frames[index]
}

private enum IconFrameCache {
    static let frames: [NSImage?] = (0..<MenuBarIconMetrics.animationFrameCount).map { index in
        guard let path = Bundle.main.path(forResource: "standup_\(index)", ofType: "png"),
              let image = NSImage(contentsOfFile: path) else {
            return nil
        }
        image.isTemplate = true
        let size = NSSize(
            width: MenuBarIconMetrics.renderedDimension,
            height: MenuBarIconMetrics.renderedDimension
        )
        image.size = size
        return image
    }
}

private func fallbackSymbol(for index: Int) -> String {
    switch index {
    case 0: return "figure.roll"
    case 1: return "figure.walk.arrival"
    case 2: return "figure.walk"
    default: return "figure.stand"
    }
}
