import EkkoCore

/// A `FeatureFlagProvider` that enables all feature flags. Set at app startup via
/// `FeatureFlags.provider = DefaultFeatureFlagProvider()`.
public struct DefaultFeatureFlagProvider: FeatureFlagProvider {
    public init() {}

    public func isEnabled(_ feature: Feature) -> Bool {
        true
    }
}
