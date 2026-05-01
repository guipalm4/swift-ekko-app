import Testing
@testable import EkkoCore

struct TestFeatureFlagProvider: FeatureFlagProvider {
    var enabledFeatures: Set<Feature>
    func isEnabled(_ feature: Feature) -> Bool { enabledFeatures.contains(feature) }
}

// .serialized prevents parallel tests from racing on FeatureFlags.provider global state
@Suite("FeatureFlags", .serialized)
struct FeatureFlagsTests {

    @Test("isEnabled returns false for a disabled feature")
    func disabledFeature() {
        let original = FeatureFlags.provider
        defer { FeatureFlags.provider = original }

        FeatureFlags.provider = TestFeatureFlagProvider(enabledFeatures: [.scheduling, .restore])
        #expect(FeatureFlags.isEnabled(.encryption) == false)
    }

    @Test("isEnabled returns true for an enabled feature")
    func enabledFeature() {
        let original = FeatureFlags.provider
        defer { FeatureFlags.provider = original }

        FeatureFlags.provider = TestFeatureFlagProvider(enabledFeatures: Set(Feature.allCases))
        #expect(FeatureFlags.isEnabled(.scheduling) == true)
    }

    @Test("all features disabled when empty set provided")
    func allDisabled() {
        let original = FeatureFlags.provider
        defer { FeatureFlags.provider = original }

        FeatureFlags.provider = TestFeatureFlagProvider(enabledFeatures: [])
        for feature in Feature.allCases {
            #expect(FeatureFlags.isEnabled(feature) == false)
        }
    }

    @Test("all features enabled when full set provided")
    func allEnabled() {
        let original = FeatureFlags.provider
        defer { FeatureFlags.provider = original }

        FeatureFlags.provider = TestFeatureFlagProvider(enabledFeatures: Set(Feature.allCases))
        for feature in Feature.allCases {
            #expect(FeatureFlags.isEnabled(feature) == true)
        }
    }

    @Test("default provider enables all Feature.allCases")
    func defaultProviderEnablesAll() {
        let original = FeatureFlags.provider
        defer { FeatureFlags.provider = original }

        FeatureFlags.provider = AllEnabledFeatureFlagProvider()
        for feature in Feature.allCases {
            #expect(FeatureFlags.isEnabled(feature) == true)
        }
    }
}
