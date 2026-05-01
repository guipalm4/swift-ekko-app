public protocol SchedulerProvider {
    func register(schedule: BackupSchedule) throws
    func unregister() throws
    func status() throws -> SchedulerStatus
}
