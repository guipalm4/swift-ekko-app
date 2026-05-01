# Handoff

**Date:** 2026-05-01
**Milestone:** M0 — Architecture & Foundation
**Branch:** `feat/m0-foundation`
**Next task:** T14 + T15 (Phase 4 — parallel)

## Completed ✓

### Phase 1 — Scaffold
- **T1** — Package.swift (5 targets, swift-argument-parser 1.7.1), full directory scaffold. Commit: `3e12032`
- **T2** — `.specs/codebase/TESTING.md`. Commit: `ea6a0b0`

### Phase 2 — EkkoCore protocols + models (parallel, all complete)
- **T3** — `FileSystemProvider` + `FileAttributes` + 8 unit tests. Commit: `2b188ef`
- **T4** — `ConfigStore` + 5 unit tests. Commit: `2321d31`
- **T5** — `SchedulerProvider` + `BackupSchedule` + `SchedulerStatus` + 7 unit tests. Commit: `59bb4ee`
- **T6** — `Feature` + `FeatureFlagProvider` + `FeatureFlags` + 5 unit tests. Commit: `07c4e39`
- **T7** — `EkkoLogger` + `LogEntry` + `LogLevel` + 4 unit tests. Commit: `3cfe698`
- **T8** — `EkkoVersion`. Commit: `2a34314`

**Phase 2 test result: 28 tests, 0 failures**

### Phase 3 — EkkaPlatform adapters (parallel, all complete)
- **T9** — `DirectFileSystemProvider` + 9 unit tests. Commit: `62c2b30`
- **T10** — `LocalConfigStore` + 5 unit tests. Commit: `9fcabbf`
- **T11** — `LaunchdScheduler` + plist template + `LaunchctlRunner` protocol + 6 unit tests. Updated `Package.swift` with resources. Commit: `36da22b`
- **T12** — `CLIInstaller` + 7 unit tests. Commit: `f34a9e6`
- **T13** — `DefaultFeatureFlagProvider` + 2 unit tests. Commit: `0a6dd1f`
- **fix** — corrected module name `EkkaPlatform→EkkoPlatform` in test imports, moved sources from wrong dir, fixed `/var→/private/var` symlink in test. Commit: `c30a591`
- **simplify** — extracted `agentLabel` constant, hoisted single `libraryURL`, fixed 5 TOCTOU patterns, `makeTempDir()` helper, `symlinkExists()` helper. Commit: `df982e5`

**Phase 3 test result: 57 tests, 0 failures**

### Phase 3 gates
- coupling-analysis: ✅ Healthy — all adapters use Contract Coupling; EkkoCore purity confirmed
- simplify: ✅ Applied — 8 findings addressed (TOCTOU, duplication, stringly-typed label, docstring)
- Architecture purity: ✅ `grep "import AppKit|import SwiftUI|import ServiceManagement" Sources/EkkoCore/` = zero results

## In Progress

Nothing — Phase 3 complete. Awaiting user approval to start Phase 4.

## Pending

### Phase 4 — App Shell + CLI Entry Point (parallel, T14–T15)

| Task | What | Depends on |
|---|---|---|
| T14 [P] | EkkoApp Xcode project + placeholder UI | T1, T8 — **requires manual Xcode GUI step** |
| T15 [P] | EkkaCLI entry point (main.swift + RootCommand + AgentTriggerCommand) | T1, T8 |

### Phase 5 — Integration + Verification (sequential, T16–T17)

## Design Decisions Made in Phase 3

- **LaunchdScheduler plist template**: embedded as `static let plistTemplate` string (not loaded from bundle) — avoids SPM resource resolution complexity in tests. File `com.ekko.agent.plist` mirrors the constant and is declared as `.copy` resource.
- **CLIInstaller static API**: kept for T16 wiring convenience. Instance API (`performInstall`, `performUninstall`, `checkInstalled`) exposed for testability.
- **ConfigError**: no associated values on error cases — keeps error type `Equatable` and API clean. Defer richer error info to M1 if needed.
- **fileManager injection in DirectFileSystemProvider**: kept as `init(fileManager:)` parameter for future testability (tests use temp dirs rather than mock FileManager currently).

## Blockers

None.

## Environment Notes

- Swift Testing requires Xcode.app — prefix ALL commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
- T14 requires a manual Xcode GUI step (create `.xcodeproj`) — agent must post the MANUAL STEP REQUIRED block and wait
