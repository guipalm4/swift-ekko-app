# Handoff

**Date:** 2026-05-01
**Milestone:** M0 — Architecture & Foundation
**Branch:** `feat/m0-foundation`
**Next task:** T9 (Phase 3 — first parallel wave)

## Completed ✓

### Phase 1 — Scaffold
- **T1** — Package.swift (5 targets, swift-argument-parser 1.7.1), full directory scaffold. `swift build` ✓. Commit: `3e12032`
- **T2** — `.specs/codebase/TESTING.md`: gate commands, coverage matrix, mock patterns. Commit: `ea6a0b0`
- **chore** — `.gitignore`. Commit: `ccc6b24`

### Phase 2 — EkkoCore protocols + models (parallel, all complete)
- **T3** — `FileSystemProvider` protocol + `FileAttributes` model + 8 unit tests. Commit: `2b188ef`
- **T4** — `ConfigStore` protocol + 5 unit tests (round-trip, delete, nil-for-missing). Commit: `2321d31`
- **T5** — `SchedulerProvider` + `BackupSchedule` (custom Codable for associated-value enum) + `SchedulerStatus` + 7 unit tests. Commit: `59bb4ee`
- **T6** — `Feature` enum + `FeatureFlagProvider` + `FeatureFlags` (internal `AllEnabledFeatureFlagProvider` default) + 5 unit tests. Commit: `07c4e39`
- **T7** — `EkkoLogger` (JSON-lines, retention pruning, os_log for .error) + `LogEntry` + `LogLevel` + 4 unit tests. Commit: `3cfe698`
- **T8** — `EkkoVersion` (`current = "0.1.0"`, `build = "1"`). Commit: `2a34314`

### Docs / chore
- `chore`: CLAUDE.md build commands updated with `DEVELOPER_DIR=...` prefix (required for Swift Testing)
- `chore`: EkkaPlatformTests placeholder fixed (removed premature `import Testing`)

**Phase 2 test result: 28 tests, 0 failures**

## In Progress

Nothing — Phase 2 complete and committed. Awaiting user approval to start Phase 3.

## Pending

### Phase 3 — EkkaPlatform adapters (parallel, T9–T13)
Depend on Phase 2 protocols being complete (✓).

| Task | What | Depends on |
|---|---|---|
| T9 [P] | `DirectFileSystemProvider` + tests | T3 |
| T10 [P] | `LocalConfigStore` + tests | T4 |
| T11 [P] | `LaunchdScheduler` + plist template + tests | T5 |
| T12 [P] | `CLIInstaller` + tests | T1 |
| T13 [P] | `DefaultFeatureFlagProvider` + tests | T6 |

### Phase 4 — App Shell + CLI entry point (parallel, T14–T15)
### Phase 5 — Integration + Verification (sequential, T16–T17)

## Blockers

None.

## Environment Notes

- **Swift Testing requires Xcode.app** — all gate commands need `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` prefix. CommandLineTools does not include `Testing.framework` for macOS.
- Use `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` for all DOD checks.

## Design Decisions Made in Phase 2

- **EkkoLogger** implemented as instance struct (not purely static) for testability; static `shared` can be added in T16 wiring if needed.
- **FeatureFlags.provider** uses `any FeatureFlagProvider` existential (Swift 5.7+ syntax); default is internal `AllEnabledFeatureFlagProvider` since EkkoCore cannot import EkkaPlatform. EkkaPlatform's `DefaultFeatureFlagProvider` replaces it at app startup (T16).
- **MockSchedulerProvider** is a `class` (not struct) because `SchedulerProvider` protocol methods are non-mutating; struct conformance would require `mutating` which the protocol doesn't allow.
- **BackupSchedule.Interval** uses manual Codable with discriminator key `type` (Swift cannot auto-synthesize Codable for enums with associated values).
