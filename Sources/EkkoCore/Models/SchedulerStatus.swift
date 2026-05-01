import Foundation

public enum SchedulerStatus: Equatable {
    case active(nextFireDate: Date?)
    case inactive
    case error(String)
}
