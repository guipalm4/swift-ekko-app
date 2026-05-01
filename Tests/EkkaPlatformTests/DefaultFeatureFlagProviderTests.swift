import Testing
import EkkoCore
@testable import EkkoPlatform

@Suite("DefaultFeatureFlagProvider")
struct DefaultFeatureFlagProviderTests {

    @Test("All features are enabled by default")
    func allFeaturesAreEnabledByDefault() {
        let provider = DefaultFeatureFlagProvider()
        for feature in Feature.allCases {
            #expect(provider.isEnabled(feature), "Expected \(feature.rawValue) to be enabled by default")
        }
    }

    @Test("Conforms to FeatureFlagProvider protocol")
    func isInstanceOfFeatureFlagProvider() {
        let provider: any FeatureFlagProvider = DefaultFeatureFlagProvider()
        for feature in Feature.allCases {
            #expect(provider.isEnabled(feature))
        }
    }
}
