import EkkoCore

/// A `FeatureFlagProvider` that enables all feature flags by default.
///
/// This is the public EkkaPlatform counterpart to the internal
/// `AllEnabledFeatureFlagProvider` in EkkoCore. The app sets this at startup
/// via `FeatureFlags.provider = DefaultFeatureFlagProvider()`.
public struct DefaultFeatureFlagProvider: FeatureFlagProvider {
    public init() {}

    public func isEnabled(_ feature: Feature) -> Bool {
        true
    }
}
