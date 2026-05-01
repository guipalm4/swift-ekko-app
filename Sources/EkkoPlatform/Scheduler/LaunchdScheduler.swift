import Foundation
import EkkoCore

// MARK: - LaunchctlRunner

/// Abstraction over `launchctl` invocations, enabling injection of test doubles.
public protocol LaunchctlRunner {
    /// Runs `launchctl` with the given arguments and returns stdout.
    @discardableResult
    func run(arguments: [String]) throws -> String
}

// MARK: - ProcessLaunchctlRunner

/// Production runner — shells out to the real `launchctl` binary via `Process`.
public struct ProcessLaunchctlRunner: LaunchctlRunner {
    public init() {}

    public func run(arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let output = String(
            data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        guard process.terminationStatus == 0 else {
            let errOutput = String(
                data: stderrPipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            throw LaunchdError.launchctlFailed(
                exitCode: process.terminationStatus,
                stderr: errOutput
            )
        }

        return output
    }
}

// MARK: - LaunchdError

public enum LaunchdError: Error, Equatable {
    case templateNotFound
    case launchctlFailed(exitCode: Int32, stderr: String)
}

// MARK: - LaunchdScheduler

/// A `SchedulerProvider` that registers/unregisters a launchd LaunchAgent using a plist template.
public struct LaunchdScheduler: SchedulerProvider {

    // MARK: - Embedded plist template
    //
    // Embedded as a static constant to avoid SPM bundle-resource resolution complexity in tests.
    // The file at Sources/EkkoPlatform/Resources/com.ekko.agent.plist mirrors this content and
    // is declared as a `.copy` resource in Package.swift for reference / distribution purposes.
    static let plistTemplate: String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
            "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>io.ekko.agent</string>

            <key>ProgramArguments</key>
            <array>
                <string>__CLI_PATH__</string>
                <string>--agent-trigger</string>
            </array>

            <key>StartCalendarInterval</key>
            __SCHEDULE__

            <key>RunAtLoad</key>
            <false/>

            <key>StandardOutPath</key>
            <string>__LOG_DIR__/agent.log</string>

            <key>StandardErrorPath</key>
            <string>__LOG_DIR__/agent-error.log</string>

            <key>KeepAlive</key>
            <false/>
        </dict>
        </plist>
        """

    // MARK: - Properties

    private let runner: LaunchctlRunner
    private let plistOutputURL: URL
    private let cliPath: String
    private let logDir: String

    // MARK: - Init

    /// Production init — resolves paths from the system.
    public init() {
        let launchAgentsURL = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("LaunchAgents", isDirectory: true)
        ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/LaunchAgents")

        let logsURL = FileManager.default.urls(
            for: .libraryDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent("Logs/Ekko", isDirectory: true)
        ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/Ekko")

        let plistURL = launchAgentsURL.appendingPathComponent("io.ekko.agent.plist")

        // Resolve CLI path from the main bundle if available, fall back to a fixed location.
        let cliPath: String
        if let bundlePath = Bundle.main.executableURL?.deletingLastPathComponent()
            .appendingPathComponent("EkkaCLI").path,
           FileManager.default.fileExists(atPath: bundlePath) {
            cliPath = bundlePath
        } else {
            cliPath = "/usr/local/bin/ekko"
        }

        self.runner = ProcessLaunchctlRunner()
        self.plistOutputURL = plistURL
        self.cliPath = cliPath
        self.logDir = logsURL.path
    }

    /// Testable init — injects all dependencies.
    public init(
        runner: LaunchctlRunner,
        plistOutputURL: URL,
        cliPath: String,
        logDir: String
    ) {
        self.runner = runner
        self.plistOutputURL = plistOutputURL
        self.cliPath = cliPath
        self.logDir = logDir
    }

    // MARK: - SchedulerProvider

    public func register(schedule: BackupSchedule) throws {
        let rendered = Self.plistTemplate
            .replacingOccurrences(of: "__CLI_PATH__", with: cliPath)
            .replacingOccurrences(of: "__LOG_DIR__", with: logDir)
            .replacingOccurrences(of: "__SCHEDULE__", with: scheduleXML(for: schedule.interval))

        let dir = plistOutputURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        guard let data = rendered.data(using: .utf8) else {
            throw LaunchdError.templateNotFound
        }
        try data.write(to: plistOutputURL, options: .atomic)

        let uid = getuid()
        try runner.run(arguments: [
            "bootstrap",
            "gui/\(uid)",
            plistOutputURL.path
        ])
    }

    public func unregister() throws {
        let uid = getuid()
        // Best-effort bootout — ignore errors (agent may already be unloaded).
        try? runner.run(arguments: [
            "bootout",
            "gui/\(uid)/io.ekko.agent"
        ])

        if FileManager.default.fileExists(atPath: plistOutputURL.path) {
            try FileManager.default.removeItem(at: plistOutputURL)
        }
    }

    public func status() throws -> SchedulerStatus {
        let uid = getuid()
        do {
            let output = try runner.run(arguments: [
                "print",
                "gui/\(uid)/io.ekko.agent"
            ])
            if output.contains("state = running") {
                return .active(nextFireDate: nil)
            }
            return .inactive
        } catch {
            return .inactive
        }
    }

    // MARK: - Private helpers

    /// Generates the `StartCalendarInterval` XML value fragment for the given interval.
    private func scheduleXML(for interval: BackupSchedule.Interval) -> String {
        switch interval {
        case .hourly:
            return "<dict><key>Minute</key><integer>0</integer></dict>"
        case .daily(let hour, let minute):
            return "<dict><key>Hour</key><integer>\(hour)</integer><key>Minute</key><integer>\(minute)</integer></dict>"
        case .weekly(let weekday, let hour, let minute):
            return "<dict><key>Weekday</key><integer>\(weekday)</integer><key>Hour</key><integer>\(hour)</integer><key>Minute</key><integer>\(minute)</integer></dict>"
        }
    }
}
