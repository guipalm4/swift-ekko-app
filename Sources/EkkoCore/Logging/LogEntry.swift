import Foundation

public struct LogEntry: Codable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        level: LogLevel,
        category: String,
        message: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.category = category
        self.message = message
    }
}
