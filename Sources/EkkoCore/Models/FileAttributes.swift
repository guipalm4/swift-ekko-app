import Foundation

public struct FileAttributes {
    public let size: Int64
    public let modificationDate: Date
    public let isDirectory: Bool

    public init(size: Int64, modificationDate: Date, isDirectory: Bool) {
        self.size = size
        self.modificationDate = modificationDate
        self.isDirectory = isDirectory
    }
}
