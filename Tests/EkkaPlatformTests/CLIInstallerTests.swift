import Testing
import Foundation
@testable import EkkoPlatform

@Suite("CLIInstaller")
struct CLIInstallerTests {

    // MARK: - Helpers

    private struct TestFixture {
        let installer: CLIInstaller
        let tempDir: URL
        let installDir: URL
        let fakeBinary: URL
    }

    /// Creates a unique temporary directory with a fake CLI binary and a separate install dir.
    private func makeFixture() throws -> TestFixture {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("CLIInstallerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Fake CLI binary so checkInstalled() can confirm the symlink destination exists.
        let fakeBinary = tempDir.appendingPathComponent("EkkaCLI")
        try "#!/bin/sh\necho ekko".write(to: fakeBinary, atomically: true, encoding: .utf8)

        // Separate subdirectory as the install target, mirroring /usr/local/bin.
        let installDir = tempDir.appendingPathComponent("bin", isDirectory: true)
        try FileManager.default.createDirectory(at: installDir, withIntermediateDirectories: true)

        let installer = CLIInstaller(bundleURL: fakeBinary, installDir: installDir)
        return TestFixture(installer: installer, tempDir: tempDir, installDir: installDir, fakeBinary: fakeBinary)
    }

    // MARK: - Tests

    @Test("installCreatesSymlink")
    func installCreatesSymlink() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        try f.installer.performInstall()

        let symlinkPath = f.installDir.appendingPathComponent("ekko").path
        let destination = try FileManager.default.destinationOfSymbolicLink(atPath: symlinkPath)
        #expect(!destination.isEmpty)
    }

    @Test("installCreatesInstallDirIfMissing")
    func installCreatesInstallDirIfMissing() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        let missingInstallDir = f.tempDir.appendingPathComponent("nonexistent-bin", isDirectory: true)
        let installer = CLIInstaller(bundleURL: f.fakeBinary, installDir: missingInstallDir)

        try installer.performInstall()

        #expect(FileManager.default.fileExists(atPath: missingInstallDir.path))
        let symlinkPath = missingInstallDir.appendingPathComponent("ekko").path
        #expect(FileManager.default.fileExists(atPath: symlinkPath))
    }

    @Test("installOverwritesStaleSymlink")
    func installOverwritesStaleSymlink() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        try f.installer.performInstall()
        // Second install must not throw.
        try f.installer.performInstall()

        let symlinkPath = f.installDir.appendingPathComponent("ekko").path
        let destination = try FileManager.default.destinationOfSymbolicLink(atPath: symlinkPath)
        #expect(!destination.isEmpty)
    }

    @Test("isInstalledReturnsTrueAfterInstall")
    func isInstalledReturnsTrueAfterInstall() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        try f.installer.performInstall()
        #expect(f.installer.checkInstalled() == true)
    }

    @Test("isInstalledReturnsFalseBeforeInstall")
    func isInstalledReturnsFalseBeforeInstall() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        #expect(f.installer.checkInstalled() == false)
    }

    @Test("uninstallRemovesSymlink")
    func uninstallRemovesSymlink() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        try f.installer.performInstall()
        try f.installer.performUninstall()
        #expect(f.installer.checkInstalled() == false)
    }

    @Test("uninstallIsNoOpWhenNotInstalled")
    func uninstallIsNoOpWhenNotInstalled() throws {
        let f = try makeFixture()
        defer { try? FileManager.default.removeItem(at: f.tempDir) }

        // Must not throw on a fresh instance with no symlink present.
        try f.installer.performUninstall()
    }
}
