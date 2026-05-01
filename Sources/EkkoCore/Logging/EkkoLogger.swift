import Foundation
import os

public struct EkkoLogger {
    private let configStore: (any ConfigStore)?

    public init(configStore: (any ConfigStore)? = nil) {
        self.configStore = configStore
    }

    public func log(
        _ message: String,
        level: LogLevel,
        category: String,
        file: String = #file,
        line: Int = #line
    ) {
        let entry = LogEntry(level: level, category: category, message: message)

        if level == .error {
            let osLogger = Logger(subsystem: "io.ekko", category: category)
            osLogger.error("\(message, privacy: .public)")
        }

        writeEntry(entry)
    }

    // MARK: - Private

    private var logFileURL: URL {
        if let path = try? configStore?.load(String.self, forKey: "logFilePath") {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Ekko/ekko.log")
    }

    private var retentionDays: Int {
        if let days = try? configStore?.load(Int.self, forKey: "logRetentionDays") {
            return days
        }
        return 7
    }

    private func writeEntry(_ entry: LogEntry) {
        let url = logFileURL
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            var entries: [LogEntry] = []
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url) {
                entries = data
                    .split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
                    .compactMap { try? decoder.decode(LogEntry.self, from: Data($0)) }
            }

            let cutoff = Date().addingTimeInterval(-Double(retentionDays) * 86_400)
            entries = entries.filter { $0.timestamp > cutoff }
            entries.append(entry)

            var output = Data()
            for e in entries {
                output.append(contentsOf: try encoder.encode(e))
                output.append(UInt8(ascii: "\n"))
            }
            try output.write(to: url, options: .atomic)
        } catch {
            // Logging must never crash the caller
        }
    }
}
