# Roadmap

**Current Milestone:** M0 — Architecture & Foundation
**Status:** Planning

---

## M0 — Architecture & Foundation

**Goal:** No user-facing features. Resolve all architectural ambiguities, establish module structure, wire cross-cutting infrastructure. Nothing in M1+ can be built correctly without these decisions locked.
**Target:** Before any feature implementation begins.

### Features

**Project Scaffolding** — PLANNED

- Swift package layout: `EkkoCore` (pure Swift framework), `EkkoPlatform` (launchd/direct FS adapters), `EkkoApp` (SwiftUI target), `EkkoCLI` (executable target)
- `EkkoCore` declares protocols: `FileSystemProvider`, `ConfigStore`, `SchedulerProvider` — no concrete platform implementations
- `EkkoPlatform` provides: `LaunchdScheduler`, `DirectFileSystemProvider`, `LocalConfigStore`, `CLIInstaller`
- Xcode project + scheme configuration for all four targets

**Cross-Cutting Infrastructure** — PLANNED

- i18n: `String(localized:)` convention enforced, `.xcstrings` catalog, EN as base locale
- Feature flag system: lightweight enum-based registry in `EkkoCore`, evaluated at runtime, no network calls
- Logging foundation: structured log writer in `EkkoCore`, consumed by both UI and CLI
- Notarization pipeline: entitlements, signing config, `notarytool` workflow documented

**launchd Agent Setup** — PLANNED

- `com.ekko.agent.plist` template in `EkkoApp` bundle resources
- `LaunchdScheduler` writes plist to `~/Library/LaunchAgents/` and calls `launchctl bootstrap`
- Verify headless execution without foreground app

---

## M1 — Backup Core (Working Alpha)

**Goal:** A user can manually trigger a backup of selected files/folders to an external storage device. Incremental. Configurable sources including isolated dotfiles. Logs retained per settings.
**Target:** First usable build.

### Features

**Source Configuration** — PLANNED

- Add/remove folders as backup sources
- Add/remove isolated individual files (e.g. `.zshrc`, `.gitconfig`)
- Persist configuration to disk

**Destination Management** — PLANNED

- Select an external volume as the backup destination
- Validate destination is writable and has sufficient space

**Incremental Backup Engine** — PLANNED

- Copy only files that changed since last backup (compare mtime + size; checksum on conflict)
- Space-optimized: no duplicate file copies across backup runs
- Progress reporting (events that UI and CLI can consume)

**Manual Trigger** — PLANNED

- "Backup now" via UI
- "Backup now" via CLI (`ekko backup now`)

**Log System** — PLANNED

- Structured per-run log (start time, files copied, errors, duration)
- Log retention configurable in days
- Accessible from UI and CLI

---

## M2 — Automation & Security

**Goal:** Backups run on a schedule without user interaction. Backed-up data can be encrypted and restored. Retention limits enforced automatically.
**Target:** Feature-complete for v1 scope.

### Features

**Scheduled Backups** — PLANNED

- Configure backup schedule (hourly / daily / weekly)
- Headless execution: runs without the app in the foreground, no UI required
- Mechanism determined by ARCH-001/002 resolution (launchd agent or BGTaskScheduler)

**Encryption** — PLANNED

- Per-configuration toggle: encrypt backup output (CryptoKit AES-GCM)
- Key derived from user password (PBKDF2); key never stored on disk

**Restore** — PLANNED

- Select a backup snapshot to restore from
- Password required before any restore operation begins
- Restore to original path or alternate destination

**Backup Retention** — PLANNED

- Configurable: keep N most recent snapshots, or snapshots newer than X days
- Auto-prune on each backup run

---

## M3 — Interfaces & Distribution (v1.0)

**Goal:** Polished, shippable product. Full SwiftUI interface, CLI at feature parity, App Store-ready, installable via `.dmg`.
**Target:** v1.0 public release.

### Features

**SwiftUI Interface Polish** — PLANNED

- Complete settings UI (sources, destination, schedule, encryption, retention, logs)
- Status dashboard (last backup time, next scheduled run, log viewer)
- Onboarding flow for first-time setup

**CLI Interface** — PLANNED

- Full command coverage: `ekko backup now`, `ekko backup status`, `ekko config`, `ekko restore`, `ekko logs`
- Machine-readable output (`--json` flag)

**i18n Completion** — PLANNED

- All UI strings localized (EN + PT-BR as launch locales)
- CLI output localized

**Feature Flags Wired** — PLANNED

- All M1–M3 capabilities gated behind feature flags
- Admin override mechanism for testing unreleased flags locally

**Distribution** — PLANNED

- `.dmg` installer with drag-to-Applications
- App Store submission (sandbox entitlements, privacy manifest, App Review prep)
- CLI binary distribution strategy executed (per ARCH-001 decision)

---

## Future Considerations

- Device auto-detection: trigger backup automatically when target HD is connected
- Multiple named backup profiles (different source/destination/schedule combos)
- Completion and failure notifications (UserNotifications)
- Homebrew tap for CLI distribution
- Additional locales beyond EN + PT-BR
- Cloud storage destinations (iCloud Drive, SMB network share)
