import Foundation
import EkkoCore

public struct DirectFileSystemProvider: FileSystemProvider {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func copy(from source: URL, to destination: URL) async throws {
        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: source, to: destination)
    }

    public func contents(ofDirectory url: URL) async throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )
    }

    public func attributes(ofItem url: URL) async throws -> FileAttributes {
        let attrs = try fileManager.attributesOfItem(atPath: url.path)
        let size = (attrs[.size] as? Int64) ?? Int64((attrs[.size] as? Int) ?? 0)
        let modificationDate = (attrs[.modificationDate] as? Date) ?? Date.distantPast
        let fileType = attrs[.type] as? FileAttributeType
        let isDirectory = fileType == .typeDirectory
        return FileAttributes(size: size, modificationDate: modificationDate, isDirectory: isDirectory)
    }

    public func createDirectory(at url: URL) async throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    public func removeItem(at url: URL) async throws {
        try fileManager.removeItem(at: url)
    }

    public func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}
