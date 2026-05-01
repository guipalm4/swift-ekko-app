import Foundation

// MARK: - CLIInstaller

/// Manages the symlink from `/usr/local/bin/ekko` to the bundled CLI binary.
///
/// Use the static convenience API for production. Use the designated `init(bundleURL:installDir:)`
/// in tests so real filesystem paths are never touched.
public struct CLIInstaller {

    private let bundleURL: URL
    private let installDir: URL

    // MARK: - Inits

    /// Production init — resolves the CLI binary from `Bundle.main`.
    public init() {
        self.init(
            bundleURL: Bundle.main.bundleURL
                .appendingPathComponent("Contents/MacOS/EkkaCLI"),
            installDir: URL(fileURLWithPath: "/usr/local/bin")
        )
    }

    /// Testable init — inject arbitrary URLs so tests never touch real system paths.
    public init(bundleURL: URL, installDir: URL) {
        self.bundleURL = bundleURL
        self.installDir = installDir
    }

    // MARK: - Static Convenience API

    /// The URL to the bundled CLI binary resolved from `Bundle.main`.
    public static var cliURL: URL { CLIInstaller().bundleURL }

    /// Returns `true` if the CLI symlink is present and points to a valid path.
    public static var isInstalled: Bool { CLIInstaller().checkInstalled() }

    /// Installs (or refreshes) the CLI symlink at `/usr/local/bin/ekko`.
    public static func install() throws { try CLIInstaller().performInstall() }

    /// Removes the CLI symlink. No-op if the symlink is not present.
    public static func uninstall() throws { try CLIInstaller().performUninstall() }

    // MARK: - Instance API

    /// Returns `true` if `<installDir>/ekko` is a symlink pointing to an existing file.
    public func checkInstalled() -> Bool {
        let linkPath = symlinkPath
        guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: linkPath) else {
            return false
        }
        return FileManager.default.fileExists(atPath: destination)
    }

    /// Creates `installDir` if needed, then creates (or overwrites) the symlink
    /// `<installDir>/ekko → bundleURL.path`.
    public func performInstall() throws {
        let fm = FileManager.default

        // Ensure the install directory exists.
        if !fm.fileExists(atPath: installDir.path) {
            try fm.createDirectory(at: installDir, withIntermediateDirectories: true)
        }

        let linkPath = symlinkPath

        // Remove a stale symlink (or any existing item) before creating a fresh one.
        if fm.fileExists(atPath: linkPath) || (try? fm.destinationOfSymbolicLink(atPath: linkPath)) != nil {
            try fm.removeItem(atPath: linkPath)
        }

        try fm.createSymbolicLink(atPath: linkPath, withDestinationPath: bundleURL.path)
    }

    /// Removes the `<installDir>/ekko` symlink. No-op if it is not present.
    public func performUninstall() throws {
        let linkPath = symlinkPath
        guard FileManager.default.fileExists(atPath: linkPath)
                || (try? FileManager.default.destinationOfSymbolicLink(atPath: linkPath)) != nil
        else {
            return
        }
        try FileManager.default.removeItem(atPath: linkPath)
    }

    // MARK: - Private

    private var symlinkPath: String {
        installDir.appendingPathComponent("ekko").path
    }
}
