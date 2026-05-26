import Foundation

public protocol LocalDebugLogging: AnyObject {
    func write(_ message: String)
}

public final class LocalDebugLog: LocalDebugLogging {
    public static let shared = LocalDebugLog()

    public let fileURL: URL

    private let maxBytes: UInt64
    private let fileManager: FileManager
    private let dateProvider: () -> Date
    private let dateFormatter = ISO8601DateFormatter()
    private let queue = DispatchQueue(label: "fun.built4.standup.local-debug-log")

    public init(
        fileURL: URL = LocalDebugLog.defaultFileURL(),
        maxBytes: UInt64 = 512 * 1024,
        fileManager: FileManager = .default,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.fileURL = fileURL
        self.maxBytes = maxBytes
        self.fileManager = fileManager
        self.dateProvider = dateProvider
    }

    public static func defaultFileURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Standup")
            .appendingPathComponent("standup.log")
    }

    public func write(_ message: String) {
        queue.sync {
            do {
                try rotateIfNeeded()
                try fileManager.createDirectory(
                    at: fileURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                let line = "\(dateFormatter.string(from: dateProvider())) \(message)\n"
                let data = Data(line.utf8)

                if !fileManager.fileExists(atPath: fileURL.path) {
                    fileManager.createFile(atPath: fileURL.path, contents: nil)
                }

                let handle = try FileHandle(forWritingTo: fileURL)
                defer {
                    try? handle.close()
                }
                try handle.seekToEnd()
                handle.write(data)
            } catch {
                print("Standup debug log write failed: \(error)")
            }
        }
    }

    private func rotateIfNeeded() throws {
        guard let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value >= maxBytes else {
            return
        }

        let rotatedURL = fileURL.deletingPathExtension().appendingPathExtension("log.1")
        if fileManager.fileExists(atPath: rotatedURL.path) {
            try fileManager.removeItem(at: rotatedURL)
        }
        try fileManager.moveItem(at: fileURL, to: rotatedURL)
    }
}
