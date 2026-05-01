# M0 — Architecture & Foundation Tasks

**Design**: `.specs/features/m0-foundation/design.md`
**Status**: In Progress

---

## Gate Check Commands

| Gate | Command | When |
|---|---|---|
| `build` | `swift build` | Compilation only — no tests |
| `quick` | `swift test --filter <TargetTests>` | Unit tests for one target |
| `full` | `swift test` | All SPM tests |
| `app-build` | `xcodebuild build -scheme EkkoApp -destination 'platform=macOS'` | App target compiles |

---

## Execution Plan

### Phase 1 — Scaffold (Sequential)

Must complete before anything else: establishes the package structure all other tasks write into.

```
T1 → T2
```

### Phase 2 — EkkoCore (Parallel)

All independent files in `Sources/EkkoCore/`. Can run simultaneously after Phase 1.

```
T2 complete, then:
  ├── T3  [P]  FileSystemProvider + FileAttributes
  ├── T4  [P]  ConfigStore
  ├── T5  [P]  SchedulerProvider + models
  ├── T6  [P]  FeatureFlags
  ├── T7  [P]  EkkoLogger + LogEntry
  └── T8  [P]  Version
```

### Phase 3 — EkkoPlatform (Parallel)

Adapters depend on Core protocols. Can run simultaneously after Phase 2.

```
T3–T8 complete, then:
  ├── T9   [P]  DirectFileSystemProvider
  ├── T10  [P]  LocalConfigStore
  ├── T11  [P]  LaunchdScheduler + plist template
  ├── T12  [P]  CLIInstaller
  └── T13  [P]  DefaultFeatureFlagProvider
```

### Phase 4 — App Shell + CLI Entry Point (Parallel)

Can run alongside Phase 3 after T1 + Phase 2 complete.

```
T3–T8 complete, then:
  ├── T14  [P]  EkkoApp Xcode project + placeholder UI
  └── T15  [P]  EkkoCLI entry point
```

### Phase 5 — Integration + Verification (Sequential)

```
All phases complete, then:
  T16 → T17
```

---

## Task Breakdown

### T1: Package.swift + source directory scaffold

**What**: Create `Package.swift` defining EkkoCore, EkkoPlatform, EkkaCLI targets and their test targets. Create all `Sources/` and `Tests/` directories with `.gitkeep` placeholders.
**Where**: `Package.swift`, `Sources/`, `Tests/`
**Depends on**: None
**Reuses**: Nothing
**Requirements**: M0-01, M0-02, M0-03

**Done when**:
- [x] `Package.swift` defines: `EkkoCore` (library), `EkkoPlatform` (library, depends on EkkoCore), `EkkoCLI` (executable, depends on EkkoPlatform + `swift-argument-parser`), `EkkoCoreTests`, `EkkoPlatformTests`
- [x] `swift-argument-parser` added as SPM dependency (URL: `https://github.com/apple/swift-argument-parser`, from: `1.3.0`)
- [x] Swift tools version `5.9`, platforms: `.macOS(.v14)`
- [x] All `Sources/<Target>/` and `Tests/<Target>Tests/` directories exist
- [x] Gate passes: `swift build`

**Tests**: none
**Gate**: build
**Status**: complete — commit `3e12032`

**Verify**: `swift build` exits 0. `swift package describe` lists all 5 targets.

---

### T2: TESTING.md

**What**: Create `.specs/codebase/TESTING.md` documenting the Swift Testing setup, gate commands, and coverage matrix for this project.
**Where**: `.specs/codebase/TESTING.md`
**Depends on**: T1
**Requirements**: (meta — enables test co-location in T3–T15)

**Done when**:
- [x] Gate commands table matches the table at top of this file
- [x] Coverage matrix defines: EkkoCore protocols → unit; EkkoPlatform adapters → unit; CLI commands → unit; App UI → none (manual)
- [x] Parallelism assessment: unit tests = parallel-safe

**Tests**: none
**Gate**: none
**Status**: complete — commit `ea6a0b0`

---

### T3: FileSystemProvider protocol + FileAttributes model [P]

**What**: Define `FileSystemProvider` protocol and `FileAttributes` struct in EkkoCore. Write Swift Testing unit tests with a mock conformance.
**Where**: `Sources/EkkoCore/Protocols/FileSystemProvider.swift`, `Sources/EkkoCore/Models/FileAttributes.swift`, `Tests/EkkoCoreTests/FileSystemProviderTests.swift`
**Depends on**: T1
**Requirements**: M0-04

**Done when**:
- [x] Protocol matches design interface exactly (all 6 methods, `async throws` where specified)
- [x] `FileAttributes` is a public struct with `size: Int64`, `modificationDate: Date`, `isDirectory: Bool`
- [x] Mock conformance (`MockFileSystemProvider`) written in test file — all methods callable
- [x] Gate passes: `swift test --filter EkkoCoreTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commit `2b188ef`

---

### T4: ConfigStore protocol [P]

**What**: Define `ConfigStore` protocol in EkkoCore. Write Swift Testing unit tests with a mock conformance.
**Where**: `Sources/EkkoCore/Protocols/ConfigStore.swift`, `Tests/EkkoCoreTests/ConfigStoreTests.swift`
**Depends on**: T1
**Requirements**: M0-05

**Done when**:
- [x] Protocol matches design: `load<T: Codable>`, `save<T: Codable>`, `delete(forKey:)` — all throwing
- [x] Mock conformance written using in-memory `[String: Data]` dictionary
- [x] Round-trip test: save a `Codable` value, load it back, assert equality
- [x] Gate passes: `swift test --filter EkkoCoreTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commit `2321d31`

---

### T5: SchedulerProvider protocol + BackupSchedule + SchedulerStatus [P]

**What**: Define `SchedulerProvider` protocol and its two supporting models in EkkoCore.
**Where**: `Sources/EkkoCore/Protocols/SchedulerProvider.swift`, `Sources/EkkoCore/Models/BackupSchedule.swift`, `Sources/EkkoCore/Models/SchedulerStatus.swift`, `Tests/EkkoCoreTests/SchedulerProviderTests.swift`
**Depends on**: T1
**Requirements**: M0-06

**Done when**:
- [x] `SchedulerProvider` protocol: `register(schedule:)`, `unregister()`, `status()` — all throwing
- [x] `BackupSchedule` is `Codable`, `Equatable`; `Interval` enum has `.hourly`, `.daily(hour:minute:)`, `.weekly(weekday:hour:minute:)` cases
- [x] `SchedulerStatus` enum: `.active(nextFireDate: Date?)`, `.inactive`, `.error(String)`
- [x] Mock conformance + tests for all three status cases
- [x] Gate passes: `swift test --filter EkkoCoreTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commit `59bb4ee`

---

### T6: Feature enum + FeatureFlagProvider + FeatureFlags [P]

**What**: Define the feature flag registry in EkkoCore.
**Where**: `Sources/EkkoCore/FeatureFlags/Feature.swift`, `Sources/EkkoCore/FeatureFlags/FeatureFlagProvider.swift`, `Sources/EkkoCore/FeatureFlags/FeatureFlags.swift`, `Tests/EkkoCoreTests/FeatureFlagsTests.swift`
**Depends on**: T1
**Requirements**: M0-14, M0-15, M0-16

**Done when**:
- [x] `Feature` enum has cases: `.scheduling`, `.encryption`, `.restore`, `.cliInstaller`, `.logRetention`, `.backupRetention`; conforms to `String`, `CaseIterable`
- [x] `FeatureFlagProvider` protocol: `func isEnabled(_ feature: Feature) -> Bool`
- [x] `FeatureFlags` class: static `provider: FeatureFlagProvider` (settable), static `isEnabled(_:)` delegates to provider
- [x] Test: inject `TestFeatureFlagProvider` that disables `.encryption`, call `FeatureFlags.isEnabled(.encryption)` → returns `false` without touching production provider
- [x] Gate passes: `swift test --filter EkkoCoreTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commit `07c4e39`

---

### T7: EkkoLogger + LogEntry + LogLevel [P]

**What**: Define structured logger in EkkoCore. Logger receives its write path via an injected `ConfigStore`.
**Where**: `Sources/EkkoCore/Logging/LogLevel.swift`, `Sources/EkkoCore/Logging/LogEntry.swift`, `Sources/EkkoCore/Logging/EkkoLogger.swift`, `Tests/EkkoCoreTests/EkkoLoggerTests.swift`
**Depends on**: T1, T4 (uses ConfigStore protocol)
**Requirements**: M0-17, M0-18, M0-19

**Done when**:
- [x] `LogLevel`: `.debug`, `.info`, `.warning`, `.error` (String, Codable)
- [x] `LogEntry`: `id: UUID`, `timestamp: Date`, `level: LogLevel`, `category: String`, `message: String` (Codable)
- [x] `EkkoLogger.log(_:level:category:)` writes JSON-lines to a path from ConfigStore key `"logFilePath"`; defaults to `~/Library/Logs/Ekko/ekko.log` when key absent
- [x] Entries older than `retentionDays` (ConfigStore key `"logRetentionDays"`, default 7) are pruned on each write
- [x] Test: write 3 entries using mock ConfigStore (in-memory write path), assert JSON-lines file content; test pruning with past timestamps
- [x] Gate passes: `swift test --filter EkkoCoreTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commit `3cfe698`

---

### T8: Version.swift [P]

**What**: Define `EkkoVersion` enum as single source of truth for app version.
**Where**: `Sources/EkkoCore/Version.swift`
**Depends on**: T1
**Requirements**: M0-21

**Done when**:
- [x] `public enum EkkoVersion { public static let current = "0.1.0"; public static let build = "1" }`
- [x] Gate passes: `swift build --target EkkoCore`

**Tests**: none (trivial constant)
**Gate**: build
**Status**: complete — commit `2a34314`

---

### T9: DirectFileSystemProvider [P]

**What**: Implement `FileSystemProvider` using `Foundation.FileManager` in EkkoPlatform.
**Where**: `Sources/EkkoPlatform/FileSystem/DirectFileSystemProvider.swift`, `Tests/EkkoPlatformTests/DirectFileSystemProviderTests.swift`
**Depends on**: T3
**Requirements**: M0-03

**Done when**:
- [x] Conforms to `FileSystemProvider`; all 6 methods delegate to `FileManager`
- [x] `copy(from:to:)` creates destination parent directories if missing
- [x] Tests use `FileManager.default.temporaryDirectory` — no permanent side effects; temp dirs cleaned up in `tearDown`
- [x] Gate passes: `swift test --filter EkkoPlatformTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commits `62c2b30`, `c30a591`, `df982e5`

---

### T10: LocalConfigStore [P]

**What**: Implement `ConfigStore` backed by JSON files in `~/Library/Application Support/Ekko/`.
**Where**: `Sources/EkkoPlatform/Config/LocalConfigStore.swift`, `Tests/EkkoPlatformTests/LocalConfigStoreTests.swift`
**Depends on**: T4
**Requirements**: M0-03

**Done when**:
- [x] Conforms to `ConfigStore`; each key maps to `<AppSupport>/Ekko/<key>.json`
- [x] Creates `Ekko/` directory on first write if missing
- [x] `load` returns `nil` (not throw) when key file does not exist
- [x] Tests use a temp directory injected via `init(baseURL:)` — never writes to real App Support
- [x] Round-trip test: save `BackupSchedule`, load it back, assert equality
- [x] Gate passes: `swift test --filter EkkoPlatformTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commits `9fcabbf`, `c30a591`, `df982e5`

---

### T11: LaunchdScheduler + plist template [P]

**What**: Implement `SchedulerProvider` using launchd. Include the plist template resource.
**Where**: `Sources/EkkoPlatform/Scheduler/LaunchdScheduler.swift`, `Sources/EkkoPlatform/Resources/com.ekko.agent.plist`, `Tests/EkkoPlatformTests/LaunchdSchedulerTests.swift`
**Depends on**: T5
**Requirements**: M0-07, M0-08, M0-09, M0-10

**Done when**:
- [x] Plist template matches design schema; contains tokens `__CLI_PATH__`, `__SCHEDULE__`, `__LOG_DIR__`
- [x] `register(schedule:)`: reads template, replaces tokens, writes rendered plist to a configurable output path (default: `~/Library/LaunchAgents/io.ekko.agent.plist`), calls `launchctl bootstrap gui/<uid> <plist>`
- [x] `unregister()`: calls `launchctl bootout gui/<uid>/io.ekko.agent`, removes plist file
- [x] `status()`: runs `launchctl print gui/<uid>/io.ekko.agent`, parses output → returns `.active`, `.inactive`, or `.error`
- [x] Unit tests cover: plist token replacement (pure function, no launchctl), output path construction; launchctl calls are behind a `LaunchctlRunner` protocol (injectable mock)
- [x] Gate passes: `swift test --filter EkkoPlatformTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commits `36da22b`, `c30a591`, `df982e5`

---

### T12: CLIInstaller [P]

**What**: Implement the in-app CLI installer that symlinks the bundled binary to `/usr/local/bin/ekko`.
**Where**: `Sources/EkkoPlatform/CLI/CLIInstaller.swift`, `Tests/EkkoPlatformTests/CLIInstallerTests.swift`
**Depends on**: T1
**Requirements**: (M3 — scaffolded in M0 so EkkoApp can wire the Settings button)

**Done when**:
- [x] `CLIInstaller.cliURL`: resolves `Bundle.main` → `Contents/MacOS/EkkoCLI`; has a testable override via `init(bundleURL:installDir:)`
- [x] `install()`: creates `/usr/local/bin/` if missing; creates or overwrites symlink
- [x] `uninstall()`: removes symlink; no-ops if not present
- [x] `isInstalled`: checks symlink exists and points to a valid path
- [x] Tests use temp directories; never touch `/usr/local/bin`
- [x] Gate passes: `swift test --filter EkkoPlatformTests`

**Tests**: unit
**Gate**: quick
**Status**: complete — commits `f34a9e6`, `c30a591`, `df982e5`

---

### T13: DefaultFeatureFlagProvider [P]

**What**: Implement `FeatureFlagProvider` in EkkoPlatform with all flags enabled by default.
**Where**: `Sources/EkkoPlatform/FeatureFlags/DefaultFeatureFlagProvider.swift`, `Tests/EkkoPlatformTests/DefaultFeatureFlagProviderTests.swift`
**Depends on**: T6
**Requirements**: M0-14

**Done when**:
- [x] Conforms to `FeatureFlagProvider`; `isEnabled(_:)` returns `true` for all `Feature` cases
- [x] Test asserts all `Feature.allCases` are enabled
- [x] Gate passes: `swift test --filter EkkoPlatformTests`

**Tests**: unit
**Status**: complete — commits `0a6dd1f`, `c30a591`, `df982e5`
**Gate**: quick

---

### T14: EkkoApp Xcode project + placeholder UI [P]

**What**: Create the `EkkoApp/` Xcode project with a minimal SwiftUI shell, i18n catalog, and local package reference.
**Where**: `EkkoApp/`
**Depends on**: T1, T8 (needs Version)
**Requirements**: M0-11, M0-12, M0-13, M0-20

> **⚠️ Requires one manual Xcode GUI step:**
> 1. Open Xcode → File → New → Project → macOS → App
> 2. Product Name: `EkkoApp`, Bundle ID: `io.ekko.app`, Interface: SwiftUI, Language: Swift
> 3. Save to `ekko-app/EkkoApp/`
> 4. File → Add Package Dependencies → Add Local → select `ekko-app/` (the root Package.swift)
> 5. Add `EkkoCore` and `EkkoPlatform` to the EkkoApp target
>
> Agent handles everything else below.

**Done when**:
- [ ] `EkkoAppApp.swift`: `@main struct EkkoAppApp: App` with a single `WindowGroup { ContentView() }`
- [ ] `ContentView.swift`: placeholder showing `Text("Ekko \(EkkoVersion.current)")` — no hardcoded strings (uses `String(localized:)`)
- [ ] `Localizable.xcstrings` catalog created in EkkoApp resources with EN as base locale and PT-BR as second locale; build setting `SWIFT_EMIT_LOC_STRINGS = YES`
- [ ] App compiles and shows placeholder window
- [ ] Gate passes: `xcodebuild build -scheme EkkoApp -destination 'platform=macOS'`

**Tests**: none (UI — manual verification)
**Gate**: app-build

---

### T15: EkkaCLI entry point [P]

**What**: Implement `main.swift` and the root command with `--version`, `--help`, and `--agent-trigger` subcommands using `swift-argument-parser`.
**Where**: `Sources/EkkoCLI/main.swift`, `Sources/EkkoCLI/Commands/RootCommand.swift`, `Sources/EkkoCLI/Commands/AgentTriggerCommand.swift`
**Depends on**: T1, T8 (Version)
**Requirements**: M0-21

**Done when**:
- [ ] `ekko --version` prints `EkkoVersion.current`
- [ ] `ekko --help` lists available subcommands with descriptions
- [ ] `ekko --agent-trigger` logs `"agent triggered"` via `EkkoLogger` and exits 0
- [ ] `RootCommand` uses `@main` via `swift-argument-parser`'s `ParsableCommand`
- [ ] Gate passes: `swift build --product EkkoCLI` + `swift run EkkoCLI -- --version` prints version string

**Tests**: none (entry point — integration behavior)
**Gate**: build

**Verify**: `swift run EkkoCLI -- --version` → prints `0.1.0`

---

### T16: EkkoApp startup wiring

**What**: Wire `AppDelegate` to initialize `DefaultFeatureFlagProvider` into `FeatureFlags.provider` and call `LaunchdScheduler` registration on first launch.
**Where**: `EkkoApp/Sources/AppDelegate.swift`
**Depends on**: T11, T13, T14
**Requirements**: M0-07, M0-08

**Done when**:
- [ ] `applicationDidFinishLaunching`: sets `FeatureFlags.provider = DefaultFeatureFlagProvider()`
- [ ] On first launch (no plist at `~/Library/LaunchAgents/io.ekko.agent.plist`): calls `LaunchdScheduler().register(schedule: .init(interval: .daily(hour: 2, minute: 0)))`
- [ ] Errors from `register()` are caught and logged via `EkkoLogger` — app does not crash
- [ ] Gate passes: `xcodebuild build -scheme EkkoApp -destination 'platform=macOS'`

**Tests**: none (wiring — verified by T17 smoke test)
**Gate**: app-build

---

### T17: Final verification

**What**: Run all verification gates, confirm EkkoCore purity, and smoke-test the launchd agent.
**Where**: No new files — verification only
**Depends on**: All previous tasks
**Requirements**: All M0 requirements

**Done when**:
- [ ] `swift test` passes with 0 failures
- [ ] `grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/` → zero results
- [ ] `xcodebuild build -scheme EkkoApp -destination 'platform=macOS'` exits 0
- [ ] After launching EkkoApp once: `~/Library/LaunchAgents/io.ekko.agent.plist` exists and contains the correct CLI path
- [ ] `launchctl print gui/$(id -u)/io.ekko.agent` shows agent as loaded (or exits without "not found" error)
- [ ] `swift run EkkoCLI -- --version` prints `0.1.0`

**Tests**: full
**Gate**: full

---

## Diagram-Definition Cross-Check

| Task | Depends On (body) | Diagram Shows | Status |
|---|---|---|---|
| T1 | None | Start | ✅ |
| T2 | T1 | T1 → T2 | ✅ |
| T3 | T1 | T2 → T3 [P] | ✅ |
| T4 | T1 | T2 → T4 [P] | ✅ |
| T5 | T1 | T2 → T5 [P] | ✅ |
| T6 | T1 | T2 → T6 [P] | ✅ |
| T7 | T1, T4 | T2 → T7 [P] | ✅ |
| T8 | T1 | T2 → T8 [P] | ✅ |
| T9 | T3 | T3–T8 → T9 [P] | ✅ |
| T10 | T4 | T3–T8 → T10 [P] | ✅ |
| T11 | T5 | T3–T8 → T11 [P] | ✅ |
| T12 | T1 | T3–T8 → T12 [P] | ✅ |
| T13 | T6 | T3–T8 → T13 [P] | ✅ |
| T14 | T1, T8 | T3–T8 → T14 [P] | ✅ |
| T15 | T1, T8 | T3–T8 → T15 [P] | ✅ |
| T16 | T11, T13, T14 | All → T16 | ✅ |
| T17 | All | T16 → T17 | ✅ |

## Task Granularity Check

| Task | Scope | Status |
|---|---|---|
| T1: Package.swift + directories | 1 file + dirs | ✅ |
| T2: TESTING.md | 1 file | ✅ |
| T3: FileSystemProvider + FileAttributes | 2 related types, 1 test file | ✅ |
| T4: ConfigStore | 1 protocol, 1 test file | ✅ |
| T5: SchedulerProvider + 2 models | 3 related types (all scheduling), 1 test | ✅ |
| T6: FeatureFlags (3 files) | 1 cohesive system, 1 test file | ✅ |
| T7: EkkoLogger + LogEntry + LogLevel | 1 cohesive logging system | ✅ |
| T8: Version | 1 constant | ✅ |
| T9–T13: one adapter each | 1 file + 1 test file | ✅ |
| T14: EkkoApp shell | 1 project setup task | ✅ |
| T15: CLI entry | 3 files, 1 command system | ✅ |
| T16: Startup wiring | 1 file | ✅ |
| T17: Verification | No new files | ✅ |

## Test Co-location Validation

| Task | Layer Created | Matrix Requires | Task Says | Status |
|---|---|---|---|---|
| T3 | EkkoCore protocol | unit | unit | ✅ |
| T4 | EkkoCore protocol | unit | unit | ✅ |
| T5 | EkkoCore protocol + models | unit | unit | ✅ |
| T6 | EkkoCore feature flags | unit | unit | ✅ |
| T7 | EkkoCore logger | unit | unit | ✅ |
| T8 | EkkoCore constant | none | none | ✅ |
| T9 | EkkoPlatform adapter | unit | unit | ✅ |
| T10 | EkkoPlatform adapter | unit | unit | ✅ |
| T11 | EkkoPlatform adapter | unit | unit | ✅ |
| T12 | EkkoPlatform adapter | unit | unit | ✅ |
| T13 | EkkoPlatform adapter | unit | unit | ✅ |
| T14 | App UI | none (manual) | none | ✅ |
| T15 | CLI entry point | none (integration) | none | ✅ |
| T16 | App wiring | none (verified by T17) | none | ✅ |
| T17 | Verification only | full | full | ✅ |
