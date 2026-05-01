import Testing
import Foundation
@testable import EkkoCore

private func makeLoggerStore(logFilePath: String, retentionDays: Int = 7) throws -> MockConfigStore {
    let store = MockConfigStore()
    try store.save(logFilePath, forKey: "logFilePath")
    try store.save(retentionDays, forKey: "logRetentionDays")
    return store
}

private func makeTempLogURL() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("ekko-log-\(UUID().uuidString).log")
}

private func readEntries(from url: URL) throws -> [LogEntry] {
    guard let data = try? Data(contentsOf: url) else { return [] }
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

        let logger = EkkoLogger(configStore: try makeLoggerStore(logFilePath: url.path))
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

        let logger = EkkoLogger(configStore: try makeLoggerStore(logFilePath: url.path))
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

        let logger = EkkoLogger(configStore: try makeLoggerStore(logFilePath: url.path, retentionDays: 7))
        logger.log("fresh", level: .info, category: "new")

        let entries = try readEntries(from: url)
        #expect(entries.count == 1)
        #expect(entries[0].message == "fresh")
    }

    @Test(".error entry is written to log file")
    func errorEntryWritten() throws {
        let url = makeTempLogURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let logger = EkkoLogger(configStore: try makeLoggerStore(logFilePath: url.path))
        logger.log("critical", level: .error, category: "system")

        let entries = try readEntries(from: url)
        let entry = try #require(entries.first)
        #expect(entry.level == .error)
        #expect(entry.message == "critical")
    }
}
