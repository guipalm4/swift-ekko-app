# Ekko — Project State

## Open Decisions

_(none — all architectural decisions locked)_

## Decisions Made

- **[ARCH-001] CLI distribution strategy → Direct .dmg + in-app CLI installer**
  Distribution is a plain notarized `.dmg`, not App Store. The app exposes an "Install CLI Tools"
  action in Settings that symlinks `/usr/local/bin/ekko → EkkoApp.app/Contents/MacOS/EkkoCLI`.
  Same pattern as VS Code. Optionally publish Homebrew Cask/formula later.
  _Rationale:_ App Store sandbox cannot write to `/usr/local/bin`. Every serious GUI+CLI app
  (VS Code, Docker, Obsidian) uses direct distribution for this reason.

- **[ARCH-002] Background scheduling → plain launchd user agent**
  App writes a `.plist` to `~/Library/LaunchAgents/com.ekko.agent.plist` and bootstraps it via
  `launchctl`. No SMAppService, no BGTaskScheduler. Simpler, more reliable, standard macOS approach
  for unsandboxed apps.

- **[ARCH-003] App Store → deferred, not abandoned**
  v1 targets direct distribution only. A future sandboxed edition is enabled by the
  `EkkoPlatformSandboxed` adapter pattern (see PROJECT.md). No business logic rewrite needed
  when/if that edition is built.

- **[ARCH-004] Platform decoupling strategy → protocol-driven adapter modules**
  `EkkoCore` exposes `FileSystemProvider`, `ConfigStore`, and `SchedulerProvider` protocols.
  `EkkoPlatform` provides concrete implementations for direct macOS (no sandbox).
  Future sandboxed edition writes `EkkoPlatformSandboxed` — Core, App, and CLI targets unchanged.

## Blockers

_(none)_

## Lessons

- App Store + first-class CLI are fundamentally incompatible under the sandbox model. Apps like
  VS Code, Docker, Obsidian, and Figma are not on the App Store for exactly this reason.
- `BGTaskScheduler` is iOS-centric. For macOS background agents, launchd is the right primitive.
- Decoupling distribution from business logic via protocols costs almost nothing upfront and
  eliminates an entire class of expensive future rewrites.

## Deferred Ideas

- App Store / sandboxed edition (GUI-only, no CLI — separate target, EkkoPlatformSandboxed)
- Device auto-detection: trigger backup when external HD is plugged in
- Multiple named backup profiles
- Completion/failure notifications (UserNotifications)
- Homebrew tap for CLI distribution
- Additional locales beyond EN + PT-BR
- Cloud storage destinations
