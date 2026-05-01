public struct BackupSchedule: Equatable {
    public let interval: Interval

    public init(interval: Interval) {
        self.interval = interval
    }

    public enum Interval: Equatable {
        case hourly
        case daily(hour: Int, minute: Int)
        case weekly(weekday: Int, hour: Int, minute: Int)
    }
}

extension BackupSchedule: Codable {
    enum CodingKeys: String, CodingKey { case interval }
}

extension BackupSchedule.Interval: Codable {
    private enum CodingKeys: String, CodingKey { case type, hour, minute, weekday }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "hourly":
            self = .hourly
        case "daily":
            self = .daily(hour: try c.decode(Int.self, forKey: .hour),
                          minute: try c.decode(Int.self, forKey: .minute))
        case "weekly":
            self = .weekly(weekday: try c.decode(Int.self, forKey: .weekday),
                           hour: try c.decode(Int.self, forKey: .hour),
                           minute: try c.decode(Int.self, forKey: .minute))
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: c,
                debugDescription: "Unknown interval type")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hourly:
            try c.encode("hourly", forKey: .type)
        case .daily(let hour, let minute):
            try c.encode("daily", forKey: .type)
            try c.encode(hour, forKey: .hour)
            try c.encode(minute, forKey: .minute)
        case .weekly(let weekday, let hour, let minute):
            try c.encode("weekly", forKey: .type)
            try c.encode(weekday, forKey: .weekday)
            try c.encode(hour, forKey: .hour)
            try c.encode(minute, forKey: .minute)
        }
    }
}
