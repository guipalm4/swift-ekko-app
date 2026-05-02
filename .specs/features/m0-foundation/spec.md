# M0 — Architecture & Foundation Specification

## Problem Statement

Before any user-facing feature can be built, the project needs a locked module structure, defined protocol boundaries, and working cross-cutting infrastructure (i18n, feature flags, logging, scheduling). Building on an unstructured foundation would couple business logic to platform specifics and make the future App Store edition expensive to add.

## Goals

- [ ] Four-target Swift package compiles cleanly with correct dependency graph (EkkoCore ← EkkoPlatform ← EkkoApp / EkkoCLI)
- [ ] EkkoCore has zero AppKit/SwiftUI/launchd imports — verified by build
- [ ] launchd agent registers, fires headlessly, and is controllable from the app
- [ ] i18n, feature flag, and logging infrastructure in place and usable by M1 feature work

## Out of Scope

| Feature | Reason |
|---|---|
| Any backup logic | M1 |
| UI screens beyond app shell | M1 |
| Encryption | M2 |
| CLI commands (beyond `ekko --version`) | M1 |
| Notarization CI pipeline | Post-M0 (configure before first public release) |

---

## User Stories

### P1: Module structure with enforced protocol boundary ⭐ MVP

**User Story:** As a developer, I want `EkkoCore` to be a pure Swift module with no platform dependencies so that future platform adapters (sandboxed, non-sandboxed) can be swapped without touching business logic.

**Why P1:** Every other story in M0–M3 depends on this boundary being correct from the start. Fixing it later requires touching every file.

**Acceptance Criteria:**

1. WHEN `EkkoCore` is compiled THEN it SHALL import only Swift standard library and Foundation — no AppKit, SwiftUI, ServiceManagement, or Darwin imports
2. WHEN `EkkoPlatform` is compiled THEN it SHALL import `EkkoCore` and provide concrete types conforming to `FileSystemProvider`, `ConfigStore`, and `SchedulerProvider`
3. WHEN `EkkoApp` is compiled THEN it SHALL import `EkkoCore` + `EkkoPlatform` and depend on nothing else
4. WHEN `EkkoCLI` is compiled THEN it SHALL import `EkkoCore` + `EkkoPlatform` and depend on nothing else
5. WHEN a developer adds a `FileManager` call directly inside `EkkoCore` THEN the build SHALL fail (enforced via a `@_disfavoredOverload` or equivalent convention, documented in CLAUDE.md)

**Independent Test:** `swift build --target EkkoCore` succeeds. `grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/` returns zero results.

---

### P1: Protocol definitions ⭐ MVP

**User Story:** As a developer, I want the three core protocols defined in `EkkoCore` so that all feature work has a clear injection point for platform behaviour.

**Why P1:** Without these protocols, M1 work will bypass the boundary and require refactoring.

**Acceptance Criteria:**

1. WHEN `FileSystemProvider` is defined THEN it SHALL expose: `copy(from:to:)`, `contentsOf(directory:)`, `attributesOf(item:)`, `createDirectory(at:)`, `removeItem(at:)`, `fileExists(at:)` — all throwing, all async-capable
2. WHEN `ConfigStore` is defined THEN it SHALL expose: `load<T: Codable>(_ type:forKey:)`, `save<T: Codable>(_ value:forKey:)`, `delete(key:)` — typed, throwing
3. WHEN `SchedulerProvider` is defined THEN it SHALL expose: `register(schedule:handler:)`, `unregister()`, `status() -> SchedulerStatus`
4. WHEN any protocol method is called THEN it SHALL be invokable from both `EkkoApp` and `EkkoCLI` via the same `EkkoCore` interface

**Independent Test:** A unit test in `EkkoCoreTests` can instantiate a mock conforming to each protocol and call every method — no platform code required.

---

### P1: launchd agent infrastructure ⭐ MVP

**User Story:** As a user, I want the app to be able to run backups on a schedule without me keeping the app open, so that backups happen automatically.

**Why P1:** Headless execution is a core v1 promise. If it's not scaffolded in M0, M2 scheduling will be built incorrectly.

**Acceptance Criteria:**

1. WHEN the app runs for the first time THEN it SHALL write `com.ekko.agent.plist` to `~/Library/LaunchAgents/` if not already present
2. WHEN the plist is written THEN `LaunchdScheduler` SHALL call `launchctl bootstrap session <plist-path>` to activate the agent
3. WHEN the agent fires THEN it SHALL execute `EkkoCLI` with a reserved internal flag (e.g., `--agent-trigger`) that the CLI handles without user interaction
4. WHEN the user removes the app THEN documentation SHALL specify the manual unload command (`launchctl bootout`)
5. WHEN `LaunchdScheduler.status()` is called THEN it SHALL return `.active`, `.inactive`, or `.error` based on `launchctl print` output

**Independent Test:** After first app launch, `launchctl print system/com.ekko.agent` (or user-level equivalent) shows the agent as loaded. Manually triggering the agent fires the CLI process (visible in Console.app).

---

### P1: i18n infrastructure ⭐ MVP

**User Story:** As a developer, I want a localization convention enforced from the first line of UI code so that adding new locales later requires no string archaeology.

**Why P1:** Retrofitting i18n to existing hardcoded strings is expensive and error-prone. The cost of doing it right is near zero if started from commit 1.

**Acceptance Criteria:**

1. WHEN any user-facing string is added to `EkkoApp` or `EkkoCLI` THEN it SHALL use `String(localized: "key", bundle: .module)` — no string literals in UI code
2. WHEN the project is built THEN an `.xcstrings` catalog SHALL exist in `EkkoApp` with EN as the base locale and PT-BR as the first translation target
3. WHEN a new string key is added without a translation THEN the build SHALL emit a warning (Xcode build setting `SWIFT_EMIT_LOC_STRINGS = YES`)
4. WHEN CLI output is generated THEN it SHALL use the same localization mechanism (or a documented fallback for non-interactive/JSON output modes)

**Independent Test:** Change system language to PT-BR (or use `LANG=pt_BR` env var for CLI). Launch app — all UI strings render in PT-BR or fall back to EN gracefully with no crashes.

---

### P1: Feature flag registry ⭐ MVP

**User Story:** As a developer, I want a centralized feature flag registry in `EkkoCore` so that every major capability can be gated for modular rollout and future commercialization.

**Why P1:** Feature flags must be in Core (not Platform or App) so both CLI and UI share the same gate. Adding them later means scattered conditionals.

**Acceptance Criteria:**

1. WHEN `FeatureFlags` is queried THEN it SHALL expose a typed enum of all flags (e.g., `.encryption`, `.scheduling`, `.restore`, `.cliTools`)
2. WHEN a flag is evaluated THEN it SHALL return `Bool` from a `FeatureFlagProvider` protocol (allowing local override in tests)
3. WHEN a flag is disabled THEN the feature entry point (UI button, CLI subcommand) SHALL be hidden or return a "not available" error — enforced at the call site, not buried in the engine
4. WHEN a new major capability is added THEN a corresponding flag SHALL be added to the registry before the first line of implementation

**Independent Test:** Set `.encryption = false` via the test provider — verify that the encryption UI section is absent from the settings view and `ekko encrypt` CLI subcommand returns a clean "feature not available" message.

---

### P2: Logging foundation

**User Story:** As a developer, I want a structured log writer in `EkkoCore` so that both the UI and CLI emit consistent, parseable log entries from day one.

**Why P2:** Not needed for the build to compile, but needed before M1 backup work begins. Moving it to M0 avoids every M1 task having to invent its own logging.

**Acceptance Criteria:**

1. WHEN `EkkoLogger.log(_:level:category:)` is called THEN it SHALL write a structured entry (timestamp, level, category, message) to a log file at a path provided by `ConfigStore`
2. WHEN log level is `.error` THEN the entry SHALL also be emitted to `os_log` (visible in Console.app)
3. WHEN log retention is not yet configured THEN it SHALL default to 7 days and prune on each write
4. WHEN `EkkoCLI` runs with `--verbose` THEN it SHALL emit log entries to stdout in addition to the log file

**Independent Test:** Call `EkkoLogger.log("test", level: .info, category: "bootstrap")` — verify file is written to the expected path, pruning respects the retention default, and Console.app shows `.error` entries.

---

### P2: App shell + CLI entry point

**User Story:** As a developer, I want a minimal compilable `EkkoApp` (SwiftUI shell) and `EkkoCLI` (with `--version` and `--help`) so that the project has runnable targets from day one.

**Why P2:** Not user-facing, but gives the project a runnable binary to validate the build pipeline end-to-end before M1 begins.

**Acceptance Criteria:**

1. WHEN `EkkoApp` launches THEN it SHALL show a placeholder window with the app name and version — no content required
2. WHEN `ekko --version` is run THEN it SHALL print the current version string (from a shared `EkkoCore.Version` constant)
3. WHEN `ekko --help` is run THEN it SHALL list available subcommands (even if unimplemented) with one-line descriptions
4. WHEN `ekko --agent-trigger` is run THEN it SHALL log "agent triggered" and exit 0 — placeholder for M2 scheduling work

**Independent Test:** `swift run EkkoCLI -- --version` prints a semver string. `open EkkoApp` shows the placeholder window without crashing.

---

## Edge Cases

- WHEN the `~/Library/LaunchAgents/` directory does not exist THEN `LaunchdScheduler` SHALL create it before writing the plist
- WHEN `launchctl bootstrap` fails (agent already loaded) THEN `LaunchdScheduler` SHALL detect the existing registration and not treat it as an error
- WHEN the app is running under a test harness THEN `FeatureFlagProvider` SHALL inject test values without touching the production flag store
- WHEN a localization key is missing for the active locale THEN the app SHALL fall back to EN without crashing or logging a spurious error

---

## Requirement Traceability

| Requirement ID | Story | Status |
|---|---|---|
| M0-01 | Module structure — 4-target dependency graph | Pending |
| M0-02 | Module structure — EkkoCore zero platform imports | Pending |
| M0-03 | Module structure — EkkoPlatform adapter conformances | Pending |
| M0-04 | Protocols — FileSystemProvider definition | Pending |
| M0-05 | Protocols — ConfigStore definition | Pending |
| M0-06 | Protocols — SchedulerProvider definition | Pending |
| M0-07 | launchd — plist written on first launch | Pending |
| M0-08 | launchd — bootstrap via launchctl | Pending |
| M0-09 | launchd — agent fires EkkoCLI --agent-trigger | Pending |
| M0-10 | launchd — status() returns observable state | Pending |
| M0-11 | i18n — String(localized:) convention | Pending |
| M0-12 | i18n — .xcstrings catalog with EN + PT-BR | Pending |
| M0-13 | i18n — warning on missing translation | Pending |
| M0-14 | Feature flags — typed enum registry | Pending |
| M0-15 | Feature flags — FeatureFlagProvider protocol | Pending |
| M0-16 | Feature flags — gate enforced at call site | Pending |
| M0-17 | Logging — structured EkkoLogger | Pending |
| M0-18 | Logging — os_log for errors | Pending |
| M0-19 | Logging — 7-day default retention | Pending |
| M0-20 | App shell — placeholder EkkoApp window | Pending |
| M0-21 | CLI entry — --version / --help / --agent-trigger | Pending |

---

## Success Criteria

- [ ] `swift build` succeeds for all four targets with zero warnings on a clean checkout
- [ ] `grep -r "import AppKit\|import SwiftUI" Sources/EkkoCore/` returns zero results
- [ ] launchd agent loads, fires, and is observable in Console.app
- [ ] Switching system locale to PT-BR shows no untranslated EN strings in the app shell
- [ ] Every flag in `FeatureFlags` enum can be overridden in a unit test without touching production code
