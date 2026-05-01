public protocol FeatureFlagProvider {
    func isEnabled(_ feature: Feature) -> Bool
}
