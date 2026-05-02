import AppKit
import EkkoCore
import EkkoPlatform

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let logger = EkkoLogger()

    func applicationDidFinishLaunching(_ notification: Notification) {
        FeatureFlags.provider = DefaultFeatureFlagProvider()
        registerAgentIfFirstLaunch()
    }

    // MARK: - Private

    private func registerAgentIfFirstLaunch() {
        let plistURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/io.ekko.agent.plist")

        guard !FileManager.default.fileExists(atPath: plistURL.path) else { return }

        let schedule = BackupSchedule(interval: .daily(hour: 2, minute: 0))
        do {
            try LaunchdScheduler().register(schedule: schedule)
        } catch {
            logger.log(
                "Failed to register launchd agent on first launch: \(error)",
                level: .error,
                category: "AppDelegate"
            )
        }
    }
}
