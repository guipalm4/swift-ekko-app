# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Ekko** is a native macOS app that automates incremental backups of files and folders to external storage (USB/HDD), operable via SwiftUI interface and CLI.

Specs live in `.specs/`. Read `.specs/project/PROJECT.md`, `ROADMAP.md`, and `STATE.md` at the start of every session. Read `.claude/napkin.md` and apply it silently.

---

## Build & Test Commands

> **Environment note:** The Swift Testing framework (`import Testing`) requires Xcode.app's Swift toolchain, not CommandLineTools. All `swift test` commands must be prefixed with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

```bash
# Build all SPM targets
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift build

# Run full test suite (required for all DOD checks)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# Run tests for a single target (fast feedback during implementation only)
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter EkkoCoreTests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter EkkaPlatformTests

# Build CLI
swift build --product EkkoCLI
swift run EkkoCLI -- --version
swift run EkkoCLI -- --help

# Build app (requires Xcode project in EkkoApp/)
xcodebuild build -scheme EkkoApp -destination 'platform=macOS'

# Architecture purity check (must return zero results)
grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/
```

---

## Architecture

SPM + Xcode hybrid. Strict one-way dependency graph:

```
EkkoCore (pure Swift — protocols + models + engines)
    ↑
EkkoPlatform (concrete adapters: launchd, FileManager, config)
    ↑                   ↑
EkkoApp (SwiftUI)    EkkoCLI (swift-argument-parser)
```

`EkkoCore` declares protocols only: `FileSystemProvider`, `ConfigStore`, `SchedulerProvider`, `FeatureFlagProvider`. All concrete implementations live exclusively in `EkkoPlatform`.

**Hard invariant:** `grep -r "import AppKit\|import SwiftUI\|import ServiceManagement" Sources/EkkoCore/` must return zero results at all times. Any violation blocks task completion.

---

## Key Conventions

- All user-facing strings: `String(localized: "key", bundle: .module)` — no bare string literals in UI or CLI output
- All paths (App Support, Logs, LaunchAgents): injected via `ConfigStore`, never hardcoded in `EkkoCore`
- launchd agent label: `io.ekko.agent` — CLI path resolved from `Bundle.main` at registration time
- Feature flags: `FeatureFlags.isEnabled(feature)` checked at every capability entry point
- Tests: Swift Testing (`#expect`, `#require`) — never `XCTAssert`
- One external dependency only: `swift-argument-parser`, scoped to `EkkoCLI` target

---

## Distribution

Direct `.dmg` — not App Store. No sandbox entitlements.
CLI symlink: `/usr/local/bin/ekko → <AppBundle>/Contents/MacOS/EkkoCLI`

---

## AI-Assisted Development Workflow

This entire codebase is developed by Claude Code. The workflow below is the contract between the AI agent and the user. Follow it exactly.

### Git Setup

```bash
git init
git checkout -b feat/m0-foundation   # one branch per milestone
```

Branch naming: `feat/<milestone-slug>` (e.g. `feat/m0-foundation`, `feat/m1-backup-core`).
Merge to `main` only after the user approves the full milestone.

### Commit Format

```
feat(m0): T1 — Package.swift scaffold [M0-01]
feat(m0): T3 — FileSystemProvider protocol + FileAttributes [M0-04]
fix(m0): T9 — correct async throws signature in DirectFileSystemProvider [M0-03]
```

Pattern: `<type>(<milestone>): T<N> — <description> [<requirement-id>]`

### Execution Model

#### Sequential tasks → main context
The orchestrator implements directly, one at a time.

#### Parallel tasks `[P]` → subagents
One subagent per task, dispatched simultaneously. Each subagent receives:
- Task definition (from `tasks.md`)
- Feature spec (`spec.md`)
- Design doc (`design.md`)
- This file (`CLAUDE.md`)
- Napkin (`.claude/napkin.md`)
- TESTING.md (`.specs/codebase/TESTING.md`)

Each subagent does NOT receive: chat history, other tasks' definitions, STATE.md.

#### After every phase
1. Run `swift test` (full suite)
2. Run `coupling-analysis` skill
3. Run `simplify` skill
4. Post phase summary to user (tasks completed, test count, any deviations)
5. **Wait for user approval before starting the next phase**

### Test Gate Strategy

| When | Command | Purpose |
|---|---|---|
| During implementation | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter <TargetTests>` | Fast feedback loop only |
| Task DOD check | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Catch regressions — mandatory |
| Phase DOD check | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Final confirmation before user review |

---

## Definition of Done

### Task DOD — agent only marks `complete` when ALL pass

```
[ ] All "Done when" checklist items in tasks.md are checked off [x]
[ ] swift test (full suite) passes — zero new failures vs. previous run
[ ] Zero new compiler warnings introduced
[ ] grep purity check passes (if task touches EkkoCore)
[ ] Zero bare string literals in UI/CLI output
[ ] Commit created: feat(<milestone>): T<N> — <description> [<req-id>]
[ ] tasks.md: task status set to `complete`, DOD items marked [x], commit SHA noted
[ ] HANDOFF.md: updated to reflect completed task and next pending task
```

### Phase DOD — agent posts summary and waits for user approval

```
[ ] All tasks in phase are `complete`
[ ] swift test (full suite) green
[ ] coupling-analysis: zero violations
[ ] simplify: findings addressed or deferred with justification in STATE.md
[ ] Phase summary posted: tasks done, test count, any spec deviations
[ ] User has approved before next phase begins
```

---

## Manual Step Protocol

Some tasks require user action (e.g. creating an Xcode project via GUI).

**Agent behaviour when a manual step is required:**
1. Stop implementation
2. Post a clearly formatted block:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  MANUAL STEP REQUIRED — T14
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Open Xcode
2. File → New → Project → macOS → App
3. Product Name: EkkoApp
   Bundle ID: io.ekko.app
   Interface: SwiftUI
   Language: Swift
4. Save to: ekko-app/EkkoApp/
5. File → Add Package Dependencies → Add Local → select ekko-app/ root
6. Add EkkoCore and EkkoPlatform to the EkkoApp target

When done, reply: "manual step done"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

3. Wait. Do not proceed until user confirms.

---

## Session Pause & Resume Protocol

### Pausing (end of session or interruption)

Before ending any session with work in progress:
1. Update `tasks.md` with current statuses (`complete` / `in_progress` / `blocked`)
2. Update `STATE.md` with any decisions made or blockers found
3. Create `.specs/HANDOFF.md` via `tlc-spec-driven` session-handoff

### Resuming

At the start of a new session with work in progress:
1. Read `.claude/napkin.md` (apply silently)
2. Read `.specs/HANDOFF.md`
3. Read `.specs/project/STATE.md`
4. Load current milestone `tasks.md`
5. Report: "Resuming [milestone] at [task]. Completed: X. Next: Y. Continue?"

If `HANDOFF.md` does not exist, reconstruct state from `tasks.md` statuses.

---

## Error & Blocker Handling

| Situation | Action |
|---|---|
| Gate fails, cause is obvious | Subagent self-corrects (1 retry max) |
| Gate fails, cause unclear | Escalate to `superpowers:systematic-debugging` |
| Task needs user decision | Mark `BLOCKED` in tasks.md, log in STATE.md, post to user |
| Spec ambiguity found during implementation | Stop, trigger `tlc-spec-driven` discuss |
| SPEC_DEVIATION required | Implement, mark `SPEC_DEVIATION` in commit + tasks.md, explain in phase summary |

---

## Skills Gates

Invoke these skills at the specified milestones. Non-negotiable.

| Trigger | Skill | Purpose |
|---|---|---|
| After every implementation phase | `coupling-analysis` | Verify EkkoCore ↔ EkkaPlatform boundary |
| After every implementation phase | `simplify` | Code quality and reuse review |
| Before first SwiftUI screen (M1) | `interface-design:init` | Establish macOS HIG design system |
| Before M2 merges | `security-review` | Encryption, file access, launchd surface |
| Before specifying M1 | `domain-analysis` | Map backup domain via DDD |

---

## Current State

**Milestone:** M0 — Architecture & Foundation
**Branch:** `feat/m0-foundation`
**Tasks:** `.specs/features/m0-foundation/tasks.md`
**Phase 1 complete:** T1 (scaffold), T2 (TESTING.md)
**Next:** Phase 2 — T3–T8 (EkkoCore protocols + models, parallel subagents)
