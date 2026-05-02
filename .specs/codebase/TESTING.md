# Testing — Ekko

## Framework

Swift Testing (`import Testing`, `#expect`, `#require`). Requires Xcode 16+ / Swift 5.9+. Never use `XCTAssert`.

---

## Gate Commands

| Gate | Command | When |
|---|---|---|
| `build` | `swift build` | Compilation only — no tests |
| `quick` | `swift test --filter <TargetTests>` | Unit tests for one target (fast feedback during implementation only) |
| `full` | `swift test` | All SPM targets — mandatory for task DOD and phase DOD |
| `app-build` | `xcodebuild build -scheme EkkoApp -destination 'platform=macOS'` | EkkoApp Xcode target compiles |

**Rule:** `swift test --filter` is for fast feedback only. `swift test` (full suite) is required before any task is marked `complete`.

---

## Coverage Matrix

| Layer | Target | Test Type | Notes |
|---|---|---|---|
| EkkoCore protocols | `EkkoCoreTests` | Unit | Mock conformances written in the same test file as the protocol test |
| EkkoCore models | `EkkoCoreTests` | Unit | Codable round-trip + equality |
| EkkoCore feature flags | `EkkoCoreTests` | Unit | Injectable `TestFeatureFlagProvider` |
| EkkoCore logger | `EkkoCoreTests` | Unit | Mock `ConfigStore` with in-memory write path |
| EkkoPlatform adapters | `EkkoPlatformTests` | Unit | Temp directories via `FileManager.default.temporaryDirectory`; cleaned up in teardown |
| CLI commands | N/A | Integration (manual) | Entry point — verified via `swift run EkkoCLI -- --version` |
| App UI | N/A | Manual | No automated UI tests in M0 |

---

## Parallelism

Unit tests in `EkkoCoreTests` and `EkkoPlatformTests` are **parallel-safe** — each test uses its own in-memory or temp-directory state. No shared global mutable state.

Tests that touch the live filesystem (e.g., `DirectFileSystemProvider`) use `FileManager.default.temporaryDirectory` and clean up in teardown. They do not write to `~/Library/` or `/usr/local/bin`.

Tests that call `launchctl` are behind a `LaunchctlRunner` protocol with an injectable mock — no live launchd interactions in the test suite.

---

## Mock Patterns

| Protocol | Mock Name | Location |
|---|---|---|
| `FileSystemProvider` | `MockFileSystemProvider` | `Tests/EkkoCoreTests/FileSystemProviderTests.swift` |
| `ConfigStore` | `MockConfigStore` | `Tests/EkkoCoreTests/ConfigStoreTests.swift` |
| `SchedulerProvider` | `MockSchedulerProvider` | `Tests/EkkoCoreTests/SchedulerProviderTests.swift` |
| `FeatureFlagProvider` | `TestFeatureFlagProvider` | `Tests/EkkoCoreTests/FeatureFlagsTests.swift` |
| `LaunchctlRunner` | `MockLaunchctlRunner` | `Tests/EkkoPlatformTests/LaunchdSchedulerTests.swift` |
