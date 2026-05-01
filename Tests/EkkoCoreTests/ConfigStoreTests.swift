import Testing
import Foundation
@testable import EkkoCore

final class MockConfigStore: ConfigStore {
    private var storage: [String: Data] = [:]

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

private struct TestModel: Codable, Equatable {
    let name: String
    let value: Int
}

@Suite("ConfigStore")
struct ConfigStoreTests {

    @Test("round-trip: save then load returns equal value")
    func roundTrip() throws {
        let store = MockConfigStore()
        let model = TestModel(name: "ekko", value: 42)
        try store.save(model, forKey: "model")
        let loaded = try store.load(TestModel.self, forKey: "model")
        #expect(loaded == model)
    }

    @Test("load missing key returns nil without throwing")
    func loadMissingKeyReturnsNil() throws {
        let store = MockConfigStore()
        let result = try store.load(String.self, forKey: "nonexistent")
        #expect(result == nil)
    }

    @Test("delete removes key so subsequent load returns nil")
    func deleteKey() throws {
        let store = MockConfigStore()
        try store.save("hello", forKey: "greet")
        try store.delete(forKey: "greet")
        let result = try store.load(String.self, forKey: "greet")
        #expect(result == nil)
    }

    @Test("round-trip with BackupSchedule.Interval.daily")
    func roundTripBackupScheduleDaily() throws {
        let store = MockConfigStore()
        let schedule = BackupSchedule(interval: .daily(hour: 3, minute: 30))
        try store.save(schedule, forKey: "schedule")
        let loaded = try store.load(BackupSchedule.self, forKey: "schedule")
        #expect(loaded == schedule)
    }

    @Test("round-trip with BackupSchedule.Interval.weekly")
    func roundTripBackupScheduleWeekly() throws {
        let store = MockConfigStore()
        let schedule = BackupSchedule(interval: .weekly(weekday: 2, hour: 8, minute: 15))
        try store.save(schedule, forKey: "schedule")
        let loaded = try store.load(BackupSchedule.self, forKey: "schedule")
        #expect(loaded == schedule)
    }
}
