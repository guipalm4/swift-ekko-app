import Foundation

public protocol FileSystemProvider {
    func copy(from source: URL, to destination: URL) async throws
    func contents(ofDirectory url: URL) async throws -> [URL]
    func attributes(ofItem url: URL) async throws -> FileAttributes
    func createDirectory(at url: URL) async throws
    func removeItem(at url: URL) async throws
    func fileExists(at url: URL) -> Bool
}
