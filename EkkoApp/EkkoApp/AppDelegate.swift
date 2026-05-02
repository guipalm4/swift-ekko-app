import AppKit
import EkkoCore
import EkkoPlatform

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        FeatureFlags.provider = DefaultFeatureFlagProvider()
        Task.detached(priority: .utility) {
            let logger = EkkoLogger()
            let libURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
                .first ?? FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library")
            let plistURL = libURL.appendingPathComponent("LaunchAgents/io.ekko.agent.plist")
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
}
