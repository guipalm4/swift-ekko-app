import Testing
import Foundation
@testable import EkkoPlatform

@Suite("DirectFileSystemProvider")
struct DirectFileSystemProviderTests {
    private func makeTemp() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    @Test("copyCreatesFileAtDestination")
    func copyCreatesFileAtDestination() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let source = tmp.appendingPathComponent("source.txt")
        let destination = tmp.appendingPathComponent("destination.txt")
        try Data("hello".utf8).write(to: source)

        let provider = DirectFileSystemProvider()
        try await provider.copy(from: source, to: destination)

        #expect(FileManager.default.fileExists(atPath: destination.path))
    }

    @Test("copyCreatesParentDirectoriesIfMissing")
    func copyCreatesParentDirectoriesIfMissing() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let source = tmp.appendingPathComponent("source.txt")
        let destination = tmp
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent("deep", isDirectory: true)
            .appendingPathComponent("destination.txt")
        try Data("hello".utf8).write(to: source)

        let provider = DirectFileSystemProvider()
        try await provider.copy(from: source, to: destination)

        #expect(FileManager.default.fileExists(atPath: destination.path))
    }

    @Test("contentsOfDirectoryReturnsFiles")
    func contentsOfDirectoryReturnsFiles() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let file1 = tmp.appendingPathComponent("alpha.txt")
        let file2 = tmp.appendingPathComponent("beta.txt")
        try Data().write(to: file1)
        try Data().write(to: file2)

        let provider = DirectFileSystemProvider()
        let contents = try await provider.contents(ofDirectory: tmp)

        // Resolve symlinks (/var → /private/var on macOS) before comparing
        let resultPaths = Set(contents.map { $0.resolvingSymlinksInPath().path })
        #expect(resultPaths.contains(file1.resolvingSymlinksInPath().path))
        #expect(resultPaths.contains(file2.resolvingSymlinksInPath().path))
    }

    @Test("attributesReturnsCorrectValues")
    func attributesReturnsCorrectValues() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let content = Data("known content".utf8)
        let file = tmp.appendingPathComponent("known.txt")
        try content.write(to: file)

        let provider = DirectFileSystemProvider()
        let attrs = try await provider.attributes(ofItem: file)

        #expect(attrs.size == Int64(content.count))
        #expect(attrs.isDirectory == false)
    }

    @Test("attributesOfDirectoryReturnsIsDirectory")
    func attributesOfDirectoryReturnsIsDirectory() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let provider = DirectFileSystemProvider()
        let attrs = try await provider.attributes(ofItem: tmp)

        #expect(attrs.isDirectory == true)
    }

    @Test("createDirectoryCreatesNestedDir")
    func createDirectoryCreatesNestedDir() async throws {
        let tmp = makeTemp()
        defer { try? FileManager.default.removeItem(at: tmp) }

        let nested = tmp
            .appendingPathComponent("level1", isDirectory: true)
            .appendingPathComponent("level2", isDirectory: true)

        let provider = DirectFileSystemProvider()
        try await provider.createDirectory(at: nested)

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: nested.path, isDirectory: &isDir)
        #expect(exists && isDir.boolValue)
    }

    @Test("removeItemDeletesFile")
    func removeItemDeletesFile() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let file = tmp.appendingPathComponent("todelete.txt")
        try Data().write(to: file)

        let provider = DirectFileSystemProvider()
        try await provider.removeItem(at: file)

        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("fileExistsReturnsTrueForExistingFile")
    func fileExistsReturnsTrueForExistingFile() async throws {
        let tmp = makeTemp()
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let file = tmp.appendingPathComponent("exists.txt")
        try Data().write(to: file)

        let provider = DirectFileSystemProvider()
        #expect(provider.fileExists(at: file) == true)
    }

    @Test("fileExistsReturnsFalseForMissingFile")
    func fileExistsReturnsFalseForMissingFile() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("doesnotexist.txt")

        let provider = DirectFileSystemProvider()
        #expect(provider.fileExists(at: missing) == false)
    }
}
