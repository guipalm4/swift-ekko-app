import Testing
import Foundation
@testable import EkkoCore

final class LoggerConfigStore: ConfigStore {
    private var storage: [String: Data] = [:]

    init(logFilePath: String, retentionDays: Int = 7) {
        storage["logFilePath"] = try? JSONEncoder().encode(logFilePath)
        storage["logRetentionDays"] = try? JSONEncoder().encode(retentionDays)
    }

    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = storage[key] else { return nil }
        return try JSONDecoder().decode(type, from: data)
    }

    func save<T: Codable>(_ value: T, forKey key: String) throws {
        storage[key] = try JSONEncoder().encode(value)
    }

    func delete(forKey key: String) throws {
        storage.removeValue(forKey: key)
    }
}

private func makeTempLogURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("ekko-log-\(UUID().uuidString).log")
}

private func readEntries(from url: URL) throws -> [LogEntry] {
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return data
        .split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: true)
        .compactMap { try? decoder.decode(LogEntry.self, from: Data($0)) }
}

@Suite("EkkoLogger")
struct EkkoLoggerTests {

    @Test("writes 3 entries as JSON lines")
    func writesThreeEntries() throws {
        let url = makeTempLogURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let logger = EkkoLogger(configStore: LoggerConfigStore(logFilePath: url.path))
        logger.log("first", level: .info, category: "test")
        logger.log("second", level: .debug, category: "test")
        logger.log("third", level: .warning, category: "test")

        let entries = try readEntries(from: url)
        #expect(entries.count == 3)
        #expect(entries[0].message == "first")
        #expect(entries[2].message == "third")
    }

    @Test("entry has correct level, category, message")
    func entryFields() throws {
        let url = makeTempLogURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let logger = EkkoLogger(configStore: LoggerConfigStore(logFilePath: url.path))
        logger.log("hello", level: .warning, category: "backup")

        let entries = try readEntries(from: url)
        let entry = try #require(entries.first)
        #expect(entry.level == .warning)
        #expect(entry.category == "backup")
        #expect(entry.message == "hello")
    }

    @Test("prunes entries older than retention period")
    func prunesOldEntries() throws {
        let url = makeTempLogURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let staleDate = Date().addingTimeInterval(-10 * 86_400)
        let stale = LogEntry(id: UUID(), timestamp: staleDate, level: .info, category: "old", message: "stale")
        var raw = try encoder.encode(stale)
        raw.append(UInt8(ascii: "\n"))
        try raw.write(to: url)

        let logger = EkkoLogger(configStore: LoggerConfigStore(logFilePath: url.path, retentionDays: 7))
        logger.log("fresh", level: .info, category: "new")

        let entries = try readEntries(from: url)
        #expect(entries.count == 1)
        #expect(entries[0].message == "fresh")
    }

    @Test(".error entry is written to log file")
    func errorEntryWritten() throws {
        let url = makeTempLogURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let logger = EkkoLogger(configStore: LoggerConfigStore(logFilePath: url.path))
        logger.log("critical", level: .error, category: "system")

        let entries = try readEntries(from: url)
        let entry = try #require(entries.first)
        #expect(entry.level == .error)
        #expect(entry.message == "critical")
    }
}
