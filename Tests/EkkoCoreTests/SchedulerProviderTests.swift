import Testing
import Foundation
@testable import EkkoCore

final class MockSchedulerProvider: SchedulerProvider {
    private(set) var registeredSchedule: BackupSchedule?
    private(set) var isRegistered: Bool = false

    func register(schedule: BackupSchedule) throws {
        registeredSchedule = schedule
        isRegistered = true
    }

    func unregister() throws {
        registeredSchedule = nil
        isRegistered = false
    }

    func status() throws -> SchedulerStatus {
        isRegistered ? .active(nextFireDate: nil) : .inactive
    }
}

@Suite("SchedulerProvider")
struct SchedulerProviderTests {

    @Test("status is .inactive before register")
    func statusBeforeRegister() throws {
        let provider = MockSchedulerProvider()
        #expect(try provider.status() == .inactive)
    }

    @Test("status is .active after register")
    func statusAfterRegister() throws {
        let provider = MockSchedulerProvider()
        try provider.register(schedule: BackupSchedule(interval: .hourly))
        #expect(try provider.status() == .active(nextFireDate: nil))
    }

    @Test("status is .inactive after unregister")
    func statusAfterUnregister() throws {
        let provider = MockSchedulerProvider()
        try provider.register(schedule: BackupSchedule(interval: .hourly))
        try provider.unregister()
        #expect(try provider.status() == .inactive)
    }

    @Test("BackupSchedule.Interval.hourly round-trips through Codable")
    func codableHourly() throws {
        let original = BackupSchedule(interval: .hourly)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackupSchedule.self, from: data)
        #expect(decoded == original)
    }

    @Test("BackupSchedule.Interval.daily round-trips through Codable")
    func codableDaily() throws {
        let original = BackupSchedule(interval: .daily(hour: 3, minute: 30))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackupSchedule.self, from: data)
        #expect(decoded == original)
    }

    @Test("BackupSchedule.Interval.weekly round-trips through Codable")
    func codableWeekly() throws {
        let original = BackupSchedule(interval: .weekly(weekday: 2, hour: 8, minute: 15))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackupSchedule.self, from: data)
        #expect(decoded == original)
    }
}
