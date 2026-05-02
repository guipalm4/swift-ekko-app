// Internal default — all flags ON. EkkoPlatform.DefaultFeatureFlagProvider replaces
// this at app startup (T16), keeping EkkoCore free of EkkoPlatform references.
struct AllEnabledFeatureFlagProvider: FeatureFlagProvider {
    func isEnabled(_ feature: Feature) -> Bool { true }
}

public final class FeatureFlags {
    public static var provider: any FeatureFlagProvider = AllEnabledFeatureFlagProvider()

    public static func isEnabled(_ feature: Feature) -> Bool {
        provider.isEnabled(feature)
    }
}
