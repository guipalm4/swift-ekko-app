# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Ekko** is a native macOS app that automates incremental backups of files and folders to external storage (USB/HDD), operable via SwiftUI interface and CLI.

Specs live in `.specs/`. Read `.specs/project/PROJECT.md`, `ROADMAP.md`, and `STATE.md` at the start of every session. Read `.claude/napkin.md` and apply it silently.

Before writing any build command, git operation, or file-edit script from scratch, check `.claude/playbook.md` — it contains verified recipes for recurring operations (build/test, pbxproj edits, unicode-safe file editing, git staging, naming audits).

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
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter EkkoPlatformTests

# Build CLI (run binary directly — swift run does not pass flags correctly to ArgumentParser)
swift build --product EkkoCLI
.build/debug/EkkoCLI --version
.build/debug/EkkoCLI --help

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
- **Output of `find Sources/<TargetName> -type d | sort`** — run this before dispatching and paste the result verbatim so agents write to the correct directories (SPM target names are case-sensitive; `EkkaPlatform` ≠ `EkkoPlatform`)

Each subagent does NOT receive: chat history, other tasks' definitions, STATE.md.

**Before dispatching:** always run `find Sources -type d | sort` and include the output in every subagent prompt that creates source files. This is mandatory — path errors from wrong directory names cause full rework cycles.

#### After every phase
1. Run `bash scripts/check.sh` (full gate suite — never run gates individually)
2. Run `coupling-analysis` skill
3. Run `simplify` skill — **inline** (orchestrator reads changed files and applies findings directly) when ≤10 recently-read files are in scope; spawn a subagent only for large or unfamiliar codebases where context is cold
4. Post phase summary to user (tasks completed, test count, any deviations)
5. **Wait for user approval before starting the next phase**

### Test Gate Strategy

| When | Command | Purpose |
|---|---|---|
| During implementation | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter <TargetTests>` | Fast feedback loop only |
| Task DOD check | `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test` | Catch regressions — mandatory |
| Phase DOD check | `bash scripts/check.sh` | All gates (tests + purity + warnings + xcodebuild + CLI) — **never run individually** |

---

## Definition of Done

### Task DOD — agent only marks `complete` when ALL pass

```
[ ] All "Done when" checklist items in tasks.md are checked off [x]
[ ] swift test (full suite) passes — zero new failures vs. previous run
[ ] Zero new compiler warnings introduced
[ ] grep purity check passes (if task touches EkkoCore)
[ ] Zero bare string literals in UI/CLI output
[ ] friction.md updated — bash scripts/log-friction.sh for any friction since last commit
[ ] Commit created: feat(<milestone>): T<N> — <description> [<req-id>]
[ ] tasks.md: task status set to `complete`, DOD items marked [x], commit SHA noted
[ ] HANDOFF.md: updated to reflect completed task and next pending task
```

### Phase DOD — agent posts summary and waits for user approval

```
[ ] All tasks in phase are `complete`
[ ] bash scripts/check.sh exits 0 — ALL gates green (never substitute individual commands)
    Fallback only if check.sh itself errors: use manual recipes in .claude/playbook.md
[ ] coupling-analysis: zero violations
[ ] simplify: findings addressed or deferred with justification in STATE.md
[ ] friction.md: cat .claude/friction.md → convert any patterns to scripts/ or playbook.md → clear entries
[ ] scripts/ review: any command rewritten from scratch or run 2+ times with adjustments?
    → yes: add to scripts/ or playbook.md before closing the phase
    → no:  nothing to do
[ ] HANDOFF.md: updated — completed phase, gate results, design decisions, next task
[ ] Phase summary posted: tasks done, test count, any spec deviations
[ ] User has approved before next phase begins
```

---

## Friction Logging

File: `.claude/friction.md`

Log an entry **before your next `git commit`** when any of these occur:
- Edit tool fails (file externally modified, unicode issue, etc.)
- A file must be re-read because it changed between reads
- A shell command needed adjustment after first run (wrong flags, path, output format)
- A single logical operation required 3+ tool calls to complete

**Use the script — do not use the Edit tool on friction.md directly (no file read required):**
```bash
bash scripts/log-friction.sh <type> "<description → resolution>"
# Types: edit-fail | unicode | cmd-adjust | multi-step | path-error | repeated-read | other
```

Example:
```bash
bash scripts/log-friction.sh edit-fail "Edit failed on tasks.md (unicode) → used Python str.replace()"
bash scripts/log-friction.sh cmd-adjust "git add EkkoApp/ included xcuserdata → used explicit paths"
bash scripts/log-friction.sh path-error "productName EkkaPlatform in pbxproj → grep confirmed EkkoPlatform"
```

At Phase DOD: `cat .claude/friction.md` → convert recurring patterns to `scripts/` or `playbook.md` → clear the file.

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
4. **Token efficiency retrospective:** identify what caused unnecessary token spend (wrong paths, repeated reads, avoidable retries, subagent spawning for work the orchestrator already had in context).
   - **Proven guardrails** (recurred or high-confidence): add to the `## Workflow Guardrails` section of this file (CLAUDE.md) — it is loaded every session and has no size limit.
   - **Tentative/volatile observations**: add to `.claude/napkin.md` — but napkin has a 10-item limit per category; promote to CLAUDE.md once confirmed.

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
| After every implementation phase | `coupling-analysis` | Verify EkkoCore ↔ EkkoPlatform boundary |
| After every implementation phase | `simplify` | Code quality and reuse review |
| Before first SwiftUI screen (M1) | `interface-design:init` | Establish macOS HIG design system |
| Before M2 merges | `security-review` | Encryption, file access, launchd surface |
| Before specifying M1 | `domain-analysis` | Map backup domain via DDD |

---

## Workflow Guardrails

Proven rules promoted from session retrospectives. Added here because CLAUDE.md loads every session with no size limit.

1. **[2026-05-02] Never use `Write` tool on `EkkoApp/EkkoApp/*.swift` — a hook reverts the file silently.**
   Use `Edit` tool instead. `Edit` persists correctly on Xcode target source files.

2. **[2026-05-02] Never run Phase DOD gates individually — always `bash scripts/check.sh`.**
   Running `swift test`, `xcodebuild`, purity check separately skips gates and creates false confidence. `check.sh` runs all gates and exits non-zero on any failure.

---

## Current State

**Milestone:** M1 — Backup Core (not yet started)
**Previous:** M0 complete — branch `feat/m0-foundation`, PR #1 open
**Next:** Run `domain-analysis` skill → spec M1 with `tlc-spec-driven` → create branch `feat/m1-backup-core`
