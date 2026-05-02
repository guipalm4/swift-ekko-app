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

Nothing — M0 complete. All phases and gates passed. Awaiting user approval to merge to main.

## Completed (Phase 5)

### Phase 5 — Integration + Verification (sequential, all complete)

- **T16** — `AppDelegate.swift`: wires `DefaultFeatureFlagProvider` into `FeatureFlags.provider`, dispatches launchd agent registration off main thread on first launch. Commits: `9b7b5b6`, `82d5bc4`
- **T17** — Final verification: all gates green. Commit: `f1f45fc` (sandbox fix)

**Phase 5 test result: 57 tests, 0 failures (no regressions)**

### Phase 5 gates

- coupling-analysis: ✅ Healthy — zero violations, all adapters Contract Coupling, EkkoCore purity confirmed
- simplify: ✅ Applied — 4 findings: Task.detached for off-main-thread registration, agentLabel interpolation in plistTemplate, path API consistency, removed MARK noise. Commits: `d9af713`, `82d5bc4`
- Architecture purity: ✅ zero results
- friction.md: ✅ 1 entry (Write tool reverted by hook on EkkoApp files → use Edit) → converted to playbook.md → cleared
- Full test suite: ✅ 57 tests, 0 failures
- xcodebuild: ✅ BUILD SUCCEEDED
- launchd smoke test: ✅ plist created at `~/Library/LaunchAgents/io.ekko.agent.plist`; `launchctl print gui/<uid>/io.ekko.agent` shows agent loaded (state = not running — correct, 2 AM trigger)
- CLI version: ✅ `.build/debug/EkkoCLI --version` → `0.1.0`

## Design Decisions Made in Phase 5

- **Sandbox disabled**: `ENABLE_APP_SANDBOX = NO` for both Debug and Release — direct .dmg distribution cannot write to `~/Library/LaunchAgents/` under sandbox. Xcode template defaulted to YES; corrected per spec.
- **Task.detached for launchd registration**: `Process.waitUntilExit()` (launchctl subprocess) can block for 100–500ms; dispatched off main thread to avoid stalling `applicationDidFinishLaunching`.
- **plistTemplate as computed var**: interpolates `agentLabel` to prevent label drift between template XML and `bootout`/`print` calls.
- **Use Edit (not Write) for EkkoApp/*.swift**: Write tool gets reverted by a hook on Xcode target sources; Edit persists correctly. Captured in playbook.md.

## Pending

**M0 is complete.** Next steps:
1. User approves M0 → merge `feat/m0-foundation` → `main`
2. Start M1: run `domain-analysis` skill, then `tlc-spec-driven` to spec Backup Core
3. Before first SwiftUI screen in M1: run `interface-design:init`

## Blockers

None.

## Environment Notes

- Swift Testing requires Xcode.app — prefix ALL commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`
- For EkkoApp Swift source files: always use Edit tool, never Write (Write is reverted by hook)
- launchd smoke test requires a running macOS session (not CI-only)
