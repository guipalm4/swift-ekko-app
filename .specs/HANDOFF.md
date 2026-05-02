# Handoff

**Date:** 2026-05-02
**Milestone:** M0 — Architecture & Foundation
**Branch:** `feat/m0-foundation`
**Next task:** T16 (Phase 5 — sequential)

## Completed ✓

### Phase 1 — Scaffold
- **T1** — Package.swift (5 targets, swift-argument-parser 1.7.1), full directory scaffold. Commit: `3e12032`
- **T2** — `.specs/codebase/TESTING.md`. Commit: `ea6a0b0`

**Phase 1 test result: build only**

### Phase 2 — EkkoCore protocols + models (parallel, all complete)
- **T3** — `FileSystemProvider` + `FileAttributes` + 8 unit tests. Commit: `2b188ef`
- **T4** — `ConfigStore` + 5 unit tests. Commit: `2321d31`
- **T5** — `SchedulerProvider` + `BackupSchedule` + `SchedulerStatus` + 7 unit tests. Commit: `59bb4ee`
- **T6** — `Feature` + `FeatureFlagProvider` + `FeatureFlags` + 5 unit tests. Commit: `07c4e39`
- **T7** — `EkkoLogger` + `LogEntry` + `LogLevel` + 4 unit tests. Commit: `3cfe698`
- **T8** — `EkkoVersion`. Commit: `2a34314`

**Phase 2 test result: 28 tests, 0 failures**

### Phase 3 — EkkoPlatform adapters (parallel, all complete)
- **T9** — `DirectFileSystemProvider` + 9 unit tests. Commit: `62c2b30`
- **T10** — `LocalConfigStore` + 5 unit tests. Commit: `9fcabbf`
- **T11** — `LaunchdScheduler` + plist template + `LaunchctlRunner` protocol + 6 unit tests. Commit: `36da22b`
- **T12** — `CLIInstaller` + 7 unit tests. Commit: `f34a9e6`
- **T13** — `DefaultFeatureFlagProvider` + 2 unit tests. Commit: `0a6dd1f`
- **fix** — corrected module name `EkkaPlatform→EkkoPlatform` in test imports, moved sources, fixed `/var→/private/var`. Commit: `c30a591`
- **simplify** — extracted `agentLabel`, hoisted `libraryURL`, fixed 5 TOCTOU patterns, `makeTempDir()`, `symlinkExists()`. Commit: `df982e5`

**Phase 3 test result: 57 tests, 0 failures**

### Phase 3 gates
- coupling-analysis: ✅ Healthy — all adapters use Contract Coupling; EkkoCore purity confirmed
- simplify: ✅ Applied — 8 findings addressed
- Architecture purity: ✅ zero results

### Phase 4 — App Shell + CLI Entry Point (parallel, all complete)
- **T14** — EkkoApp Xcode project + placeholder UI (`EkkoAppApp.swift`, `ContentView.swift`, `Localizable.xcstrings`). Commit: `d85effd`
- **T15** — EkkaCLI entry point (`main.swift`, `RootCommand.swift`, `AgentTriggerCommand.swift`). Commit: `583ad6c`

**Phase 4 test result: 57 tests, 0 failures (no new tests — T14/T15 have no unit tests per spec)**

### Phase 4 gates
- coupling-analysis: ✅ Healthy — EkkoApp and EkkaCLI use Contract Coupling; one dead import found
- simplify: ✅ Applied — removed unused `import EkkaPlatform` from `RootCommand.swift`. Commit: `59bfe15`
- Architecture purity: ✅ zero results
- friction.md: ✅ Empty

## In Progress

Nothing — Phase 4 complete and gates passed. Awaiting user approval to start Phase 5.

## Pending

### Phase 5 — Integration + Verification (sequential, T16–T17)

| Task | What | Depends on |
|---|---|---|
| T16 | EkkoApp startup wiring — `AppDelegate.swift`: init `DefaultFeatureFlagProvider`, register launchd agent on first launch | T11, T13, T14 |
| T17 | Final verification — full test suite, arch purity, xcodebuild, launchd smoke test, CLI version check | All |

## Design Decisions Made in Phase 4

- **RootCommand imports**: scoped to EkkoCore only (EkkaPlatform removed as unused). When M1 commands need platform adapters, they will add the import explicitly.
- **ContentView placeholder**: `Text("Ekko \(EkkoVersion.current)")` uses SwiftUI's LocalizedStringKey — correctly localized via mechanism. Semantic key names deferred to M1 when real UI is designed.

## Blockers

None.

## Environment Notes

- Swift Testing requires Xcode.app — prefix ALL commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
- T16 adds `AppDelegate.swift` to the Xcode target — use `xcodebuild build` to verify, not `swift build`
- launchd smoke test in T17 requires a running macOS session (not CI-only)
