import Testing
import Foundation
@testable import EkkoCore

final class MockFileSystemProvider: FileSystemProvider {
    var files: [URL: Data] = [:]
    var directories: Set<URL> = []
    var attributesMap: [URL: FileAttributes] = [:]

    func copy(from source: URL, to destination: URL) async throws {
        guard let data = files[source] else { throw URLError(.fileDoesNotExist) }
        files[destination] = data
    }

    func contents(ofDirectory url: URL) async throws -> [URL] {
        files.keys.filter { $0.deletingLastPathComponent() == url }
    }

    func attributes(ofItem url: URL) async throws -> FileAttributes {
        guard let attrs = attributesMap[url] else { throw URLError(.fileDoesNotExist) }
        return attrs
    }

    func createDirectory(at url: URL) async throws {
        directories.insert(url)
    }

    func removeItem(at url: URL) async throws {
        files.removeValue(forKey: url)
        directories.remove(url)
    }

    func fileExists(at url: URL) -> Bool {
        files[url] != nil || directories.contains(url)
    }
}

@Suite("FileSystemProvider")
struct FileSystemProviderTests {
    private let base = URL(string: "file:///tmp/ekko-test/")!

    @Test("copy moves data from source to destination")
    func copy() async throws {
        let provider = MockFileSystemProvider()
        let src = base.appendingPathComponent("a.txt")
        let dst = base.appendingPathComponent("b.txt")
        provider.files[src] = Data("hello".utf8)

        try await provider.copy(from: src, to: dst)

        #expect(provider.files[dst] == Data("hello".utf8))
    }

    @Test("copy throws when source does not exist")
    func copyMissingSource() async {
        let provider = MockFileSystemProvider()
        let src = base.appendingPathComponent("missing.txt")
        let dst = base.appendingPathComponent("dst.txt")

        await #expect(throws: (any Error).self) {
            try await provider.copy(from: src, to: dst)
        }
    }

    @Test("contents returns files inside directory")
    func contents() async throws {
        let provider = MockFileSystemProvider()
        let dir = base
        let file1 = dir.appendingPathComponent("one.txt")
        let file2 = dir.appendingPathComponent("two.txt")
        provider.files[file1] = Data()
        provider.files[file2] = Data()

        let result = try await provider.contents(ofDirectory: dir)

        #expect(Set(result) == [file1, file2])
    }

    @Test("attributes returns stored metadata")
    func attributes() async throws {
        let provider = MockFileSystemProvider()
        let url = base.appendingPathComponent("file.txt")
        let expected = FileAttributes(size: 1024, modificationDate: Date(timeIntervalSince1970: 0), isDirectory: false)
        provider.attributesMap[url] = expected

        let result = try await provider.attributes(ofItem: url)

        #expect(result.size == expected.size)
        #expect(result.isDirectory == expected.isDirectory)
    }

    @Test("createDirectory inserts url into directories")
    func createDirectory() async throws {
        let provider = MockFileSystemProvider()
        let dir = base.appendingPathComponent("newdir")

        try await provider.createDirectory(at: dir)

        #expect(provider.directories.contains(dir))
    }

    @Test("removeItem deletes file and directory")
    func removeItem() async throws {
        let provider = MockFileSystemProvider()
        let file = base.appendingPathComponent("del.txt")
        provider.files[file] = Data()

        try await provider.removeItem(at: file)

        #expect(provider.files[file] == nil)
    }

    @Test("fileExists returns true for known file")
    func fileExists() {
        let provider = MockFileSystemProvider()
        let url = base.appendingPathComponent("exists.txt")
        provider.files[url] = Data()

        #expect(provider.fileExists(at: url) == true)
    }

    @Test("fileExists returns false for unknown url")
    func fileExistsFalse() {
        let provider = MockFileSystemProvider()
        let url = base.appendingPathComponent("nope.txt")

        #expect(provider.fileExists(at: url) == false)
    }
}
