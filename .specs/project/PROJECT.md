# Ekko

**Vision:** A native macOS backup app that automates incremental backups of files and folders to external storage, operable via both a visual interface and the command line.
**For:** Personal use initially; designed from day one for future public distribution.
**Solves:** The lack of a lightweight, configurable macOS backup tool that works without third-party dependencies, cloud lock-in, or App Store sandbox restrictions.

## Goals

- Ship a working v1 that automates scheduled + manual backups to external storage with encryption and restore support, installable via `.dmg`.
- Architecture is protocol-driven and platform-decoupled from day one so that a future App Store / sandboxed edition requires only new adapters — not rewrites of business logic.

## Tech Stack

**Core:**

- Language: Swift 6
- UI: SwiftUI (macOS 14+ target)
- CLI: Separate Swift executable target (same Swift package, shared `EkkoCore` module)
- Crypto: CryptoKit (native — no third-party dependency)
- File I/O: Foundation / FileManager (behind a `FileSystemProvider` protocol)

**Key dependencies:** None planned. All functionality covered by Apple frameworks.

**Distribution:**
- `.dmg` direct download — primary distribution for v1
- CLI binary installed via "Install CLI Tools" button in app Settings (symlink to `/usr/local/bin/ekko`)
- Homebrew Cask / formula — optional future channel

## Module Architecture

```
EkkoCore          Pure Swift. No AppKit/SwiftUI/platform specifics.
                  Contains: BackupEngine, EncryptionEngine, RestoreEngine,
                  LogManager, FeatureFlags, Models.
                  Exposes protocols: FileSystemProvider, ConfigStore,
                  SchedulerProvider.

EkkoPlatform      Adapter implementations for direct (non-sandboxed) macOS.
                  LaunchdScheduler, DirectFileSystemProvider, LocalConfigStore,
                  CLIInstaller.

EkkoApp           SwiftUI target. Imports EkkoCore + EkkoPlatform.

EkkoCLI           Swift executable target. Imports EkkoCore + EkkoPlatform.
```

Future App Store edition = write `EkkoPlatformSandboxed` (SMAppService, security-scoped bookmarks, AppGroup config). `EkkoCore`, `EkkoApp`, and `EkkoCLI` are untouched.

## Scope

**v1 includes:**

- Scheduled (time-based) automatic backups — headless, no user interaction required
- Manual "backup now" trigger from UI and CLI
- Incremental backup — only changed files are copied
- Configurable encryption (on/off; restore requires password)
- Isolated file configuration — individual files like `.zshrc`, `.gitconfig` as backup sources
- Log retention — configurable in days
- Backup retention — configurable (number of snapshots or age)
- Backup restore — password-required
- Visual interface (SwiftUI) and CLI interface
- Feature flags — all major capabilities gated for modular rollout
- i18n — internationalization from day one

**Explicitly out of scope for v1:**

- App Store / sandboxed distribution (deferred — enabled by platform adapter design)
- Cloud/remote backup destinations
- Device auto-detection (backup on plug-in)
- Windows or Linux support
- Multiple named backup profiles
- Push notifications on backup completion/failure

## Constraints

- **Native only:** No third-party Swift packages. Apple frameworks only.
- **Space-optimized:** Minimize storage footprint (incremental, deduplication if feasible).
- **Protocol-driven platform boundary:** `EkkoCore` never imports AppKit, SwiftUI, or calls FileManager/launchd directly. All platform I/O goes through injected protocol implementations. This is the primary architectural constraint.
- **Scheduling:** `launchd` user agent (plain plist in `~/Library/LaunchAgents/`). More reliable and simpler than BGTaskScheduler for macOS background tasks outside the sandbox.
- **CLI install:** App writes symlink to `/usr/local/bin/ekko` via an "Install CLI Tools" action. Only possible because distribution is unsandboxed.
- **i18n:** All user-facing strings use `String(localized:)` from the first commit. No hardcoded English strings.
- **Notarization:** Required even without App Store. All binaries must be notarized and stapled before distribution.
- **Timeline:** None defined.
