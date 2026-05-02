# Napkin Runbook — Ekko

## Curation Rules
- Re-prioritize on every read.
- Keep recurring, high-value notes only. Max 10 items per category.
- Each item includes date + "Do instead".

---

## Architecture Guardrails (Highest Priority)

1. **[2026-05-01] EkkoCore must never import AppKit/SwiftUI/ServiceManagement**
   Do instead: run `grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/` before any PR. Zero results required. This enforces ARCH-004.

2. **[2026-05-01] Never call FileManager directly inside EkkoCore**
   Do instead: add method to `FileSystemProvider` protocol and inject via `EkkoPlatform`. EkkoCore only calls `FileSystemProvider`.

3. **[2026-05-01] Never hardcode paths (App Support, Logs, LaunchAgents) in EkkoCore**
   Do instead: all paths come from `ConfigStore` keys or are injected at init. Enables future sandbox migration.

4. **[2026-05-01] launchd plist must be re-registered when app moves (e.g. renamed or reinstalled)**
   Do instead: `LaunchdScheduler.register()` always resolves CLI path from `Bundle.main` at call time, not stored path.

---

## Skills Gates

1. **[2026-05-01] Run `coupling-analysis` after each implementation phase (M0 Phase 2, 3, 4 and each milestone)**
   Do instead: invoke skill → analyze EkkoCore ↔ EkkaPlatform boundary. Any violation blocks the phase from completing.

2. **[2026-05-01] Run `interface-design:init` before the first SwiftUI screen in M1**
   Do instead: establish macOS design system (HIG conventions, accent colors, Dark Mode, typography) before any component. Retrofitting is expensive.

3. **[2026-05-01] Run `security-review` before M2 merges (encryption + restore + launchd)**
   Do instead: invoke skill → review PBKDF2 key derivation, CryptoKit nonce handling, path traversal in file copy, launchd privilege surface.

4. **[2026-05-01] Run `simplify` after each implementation phase**
   Do instead: invoke skill → review changed code for reuse, quality, unnecessary complexity.

5. **[2026-05-01] Run `domain-analysis` before specifying M1 (Backup Core)**
   Do instead: invoke skill → map Source/Destination/Snapshot/RestorePoint/BackupRun domain before designing the engine.

---

## Swift / macOS Gotchas

1. **[2026-05-01] Swift Testing requires Xcode.app — CommandLineTools does NOT include Testing.framework for macOS**
   Do instead: prefix ALL swift build/test commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`. Without this, `import Testing` fails at compile time. Use `#expect` and `#require`, never `XCTAssert`.

2. **[2026-05-01] FeatureFlags.provider global state races in parallel Swift Testing runs**
   Do instead: any test suite that mutates a shared global must use `@Suite(..., .serialized)` to prevent inter-test races. Confirmed with FeatureFlagsTests — saves/restores provider in defer, but parallelism still causes failures without .serialized.

3. **[2026-05-01] EkkoLogger is the sole exception to the no-FileManager-in-EkkoCore rule**
   Do instead: EkkoLogger writes log files directly (it IS the I/O primitive). All other EkkoCore code must route file operations through FileSystemProvider.

4. **[2026-05-01] `launchctl bootstrap gui/<uid>` is required for user-session agents, not `system`**
   Do instead: always resolve uid via `getuid()` at runtime: `gui/\(getuid())`. Never hardcode.

5. **[2026-05-01] `swift-argument-parser` is the only approved third-party dep — scoped to EkkoCLI only**
   Do instead: confirm any new SPM dependency is added exclusively to the `EkkoCLI` target in Package.swift.

---

## Workflow Guardrails

1. **[2026-05-01] Never start a new phase without user approval of the previous one**
   Do instead: post phase summary (tasks done, test count, deviations) → wait for explicit "go ahead" before dispatching next phase.

2. **[2026-05-01] Never mark a task `complete` without running `swift test` (full suite)**
   Do instead: `swift test --filter` is for fast feedback only during implementation. Full `swift test` is mandatory before DOD.

3. **[2026-05-01] Manual steps require a formatted block and explicit wait — never proceed silently**
   Do instead: post the ⚠️ MANUAL STEP REQUIRED block (see CLAUDE.md), then stop and wait for "manual step done".

4. **[2026-05-01] Session ending with work in progress requires HANDOFF.md**
   Do instead: update tasks.md statuses → update STATE.md → create .specs/HANDOFF.md before closing.

5. **[2026-05-01] SPEC_DEVIATION must be flagged in commit message and phase summary**
   Do instead: mark `SPEC_DEVIATION` in commit body, explain in phase summary. Never deviate silently.

6. **[2026-05-01] Run `find Sources -type d | sort` before dispatching any parallel subagents that create source files**
   Do instead: paste the directory listing verbatim into every agent prompt. SPM target names are case-sensitive (`EkkoPlatform` ≠ `EkkaPlatform`); wrong paths cause full rework cycles.

7. **[2026-05-01] Run `simplify` inline when orchestrator already has the changed files in context (≤10 files)**
   Do instead: read changed files, apply findings directly in the same turn. Spawn a simplify subagent only for large or cold codebases. Spawning a subagent to re-read files you just wrote wastes tokens.

8. **[2026-05-01] Use `sed -i ''` for edits on files with Unicode characters (e.g. tasks.md with `→` arrows)**
   Do instead: when the Edit tool fails on a multi-byte character match, fall back to `sed -i ''` for that replacement. Never retry the same Edit call more than once.

9. **[2026-05-01] End every session with a token efficiency retrospective — document root causes as new Workflow Guardrails**
   Do instead: before closing, identify what caused avoidable token spend (wrong paths, repeated reads, cold-context subagents, retried edits). Add each root cause here so the next session doesn't repeat it.

## User Directives

1. **[2026-05-01] All development is AI-assisted (Claude Code) — spec every feature before implementing**
   Do instead: always run full tlc-spec-driven pipeline (Specify → Design → Tasks → Execute) before writing a line of code.

2. **[2026-05-01] Distribution is direct .dmg (not App Store) — no sandbox assumptions**
   Do instead: never add App Store entitlements or sandbox restrictions unless explicitly building the sandboxed edition. App Store is deferred to a future target.

3. **[2026-05-01] i18n from commit 1 — no hardcoded strings ever**
   Do instead: every user-facing string uses `String(localized: "key", bundle: .module)`. Reject any PR with bare string literals in UI code.
