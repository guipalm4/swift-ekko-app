import Testing
import Foundation
@testable import EkkoPlatform
import EkkoCore

// MARK: - MockLaunchctlRunner

/// A test double for `LaunchctlRunner` that records invocations and can be configured to throw.
final class MockLaunchctlRunner: LaunchctlRunner {
    private(set) var receivedArguments: [[String]] = []
    var stubbedOutput: String = ""
    var stubbedError: Error? = nil

    func run(arguments: [String]) throws -> String {
        receivedArguments.append(arguments)
        if let error = stubbedError {
            throw error
        }
        return stubbedOutput
    }

    /// The arguments from the most recent call, or nil if never called.
    var lastArguments: [String]? { receivedArguments.last }
}

// MARK: - LaunchdSchedulerTests

@Suite("LaunchdScheduler")
struct LaunchdSchedulerTests {

    // MARK: - Helpers

    private func makeTempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaunchdSchedulerTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeScheduler(
        runner: MockLaunchctlRunner,
        in dir: URL
    ) -> LaunchdScheduler {
        LaunchdScheduler(
            runner: runner,
            plistOutputURL: dir.appendingPathComponent("io.ekko.agent.plist"),
            cliPath: "/usr/local/bin/ekko",
            logDir: dir.appendingPathComponent("Logs", isDirectory: true).path
        )
    }

    // MARK: - Tests

    @Test("register writes plist with daily schedule")
    func registerWritesPlistWithDailySchedule() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        let scheduler = makeScheduler(runner: runner, in: tempDir)
        let plistURL = tempDir.appendingPathComponent("io.ekko.agent.plist")

        try scheduler.register(schedule: BackupSchedule(interval: .daily(hour: 2, minute: 0)))

        let content = try String(contentsOf: plistURL, encoding: .utf8)
        #expect(content.contains("io.ekko.agent"))
        #expect(content.contains("/usr/local/bin/ekko"))
        #expect(content.contains("<key>Hour</key><integer>2</integer>"))
        #expect(content.contains("<key>Minute</key><integer>0</integer>"))
    }

    @Test("register writes plist with weekly schedule containing Weekday key")
    func registerWritesPlistWithWeeklySchedule() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        let scheduler = makeScheduler(runner: runner, in: tempDir)
        let plistURL = tempDir.appendingPathComponent("io.ekko.agent.plist")

        try scheduler.register(schedule: BackupSchedule(interval: .weekly(weekday: 1, hour: 8, minute: 30)))

        let content = try String(contentsOf: plistURL, encoding: .utf8)
        #expect(content.contains("<key>Weekday</key><integer>1</integer>"))
        #expect(content.contains("<key>Hour</key><integer>8</integer>"))
        #expect(content.contains("<key>Minute</key><integer>30</integer>"))
    }

    @Test("register calls launchctl bootstrap with correct arguments")
    func registerCallsLaunchctl() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        let scheduler = makeScheduler(runner: runner, in: tempDir)
        let plistURL = tempDir.appendingPathComponent("io.ekko.agent.plist")

        try scheduler.register(schedule: BackupSchedule(interval: .hourly))

        let args = try #require(runner.lastArguments)
        #expect(args.count == 3)
        #expect(args[0] == "bootstrap")
        #expect(args[1].hasPrefix("gui/"))
        #expect(args[2] == plistURL.path)
    }

    @Test("unregister calls launchctl bootout with service identifier")
    func unregisterCallsBootout() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        let scheduler = makeScheduler(runner: runner, in: tempDir)

        // unregister is best-effort: ignores runner errors, so we just check the call was made.
        try scheduler.unregister()

        let args = try #require(runner.lastArguments)
        #expect(args[0] == "bootout")
        #expect(args[1].hasSuffix("/io.ekko.agent"))
    }

    @Test("status returns .active when launchctl output contains 'state = running'")
    func statusReturnsActiveWhenOutputContainsRunning() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        runner.stubbedOutput = "pid = 1234\n\tstate = running\n"
        let scheduler = makeScheduler(runner: runner, in: tempDir)

        let result = try scheduler.status()
        #expect(result == .active(nextFireDate: nil))
    }

    @Test("status returns .inactive when runner throws")
    func statusReturnsInactiveWhenRunnerThrows() throws {
        let tempDir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let runner = MockLaunchctlRunner()
        runner.stubbedError = LaunchdError.launchctlFailed(exitCode: 113, stderr: "No such process")
        let scheduler = makeScheduler(runner: runner, in: tempDir)

        let result = try scheduler.status()
        #expect(result == .inactive)
    }
}
