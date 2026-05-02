import Testing
import Foundation
@testable import EkkoPlatform
import EkkoCore

@Suite("LocalConfigStore")
struct LocalConfigStoreTests {

    // MARK: - Helpers

    /// Creates a unique temp directory for each test invocation.
    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LocalConfigStoreTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Tests

    @Test("save then load returns equal value (round-trip)")
    func saveThenLoadRoundTrip() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalConfigStore(baseURL: tempDir)
        let schedule = BackupSchedule(interval: .daily(hour: 2, minute: 0))
        try store.save(schedule, forKey: "schedule")
        let loaded = try store.load(BackupSchedule.self, forKey: "schedule")
        #expect(loaded == schedule)
    }

    @Test("load returns nil for a key that was never saved")
    func loadReturnsNilForMissingKey() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalConfigStore(baseURL: tempDir)
        let result = try store.load(BackupSchedule.self, forKey: "nonexistent")
        #expect(result == nil)
    }

    @Test("delete removes key so subsequent load returns nil")
    func deleteRemovesKey() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalConfigStore(baseURL: tempDir)
        let schedule = BackupSchedule(interval: .hourly)
        try store.save(schedule, forKey: "schedule")
        try store.delete(forKey: "schedule")
        let result = try store.load(BackupSchedule.self, forKey: "schedule")
        #expect(result == nil)
    }

    @Test("delete is a no-op for a key that was never saved")
    func deleteIsNoOpForMissingKey() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalConfigStore(baseURL: tempDir)
        // Must not throw
        try store.delete(forKey: "nonexistent")
    }

    @Test("save creates the base directory when it does not exist")
    func saveCreatesBaseDirectoryIfMissing() throws {
        let tempDir = try makeTempDir()
        // Use a non-existent subdirectory as baseURL
        let nestedDir = tempDir.appendingPathComponent("nested/config", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = LocalConfigStore(baseURL: nestedDir)
        let schedule = BackupSchedule(interval: .weekly(weekday: 1, hour: 8, minute: 0))
        // Should succeed even though nestedDir doesn't exist yet
        try store.save(schedule, forKey: "schedule")

        let loaded = try store.load(BackupSchedule.self, forKey: "schedule")
        #expect(loaded == schedule)
    }
}
