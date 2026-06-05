# AGENTS.md — Input VPN

Flutter Windows VPN client powered by sing-box. This file is the authoritative reference for architecture, conventions, and engineering rules.

---

## Commit Convention (Conventional Commits)

```
<type>(<scope>): <subject>
```

| Type | Usage |
|------|-------|
| `feat` | New functionality |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `refactor` | Internal refactor, no feature/fix |
| `test` | Tests added or updated |
| `chore` | Tooling, CI/CD, configs, deps |

**Scopes:** `lint`, `test`, `ci`, `parser`, `config`, `persist`, `dio`, `ui`, `core`, `security`, `perf`

**Examples:**
```
fix(core): prevent duplicate sing-box process launch
feat(ui): add animated connection status indicator
chore(ci): add Windows release workflow
```

Commit each logical unit of work separately. Push only when changes are self-contained and need no review.

---

## Project Structure

```
input-vpn-app/
├── .github/workflows/
│   ├── ci.yaml            # flutter analyze + flutter test on PRs
│   └── release.yaml       # tag v* → build → Inno Setup → GitHub Release
├── lib/
│   ├── globals/
│   │   ├── app_state.dart     # central ChangeNotifier, owns all business state
│   │   ├── shared_prefs.dart  # SharedPreferences singleton
│   │   ├── themes.dart
│   │   └── router.dart
│   ├── l10n/
│   │   └── app_strings.dart   # EN/RU localizations
│   ├── managers/              # high-level orchestrators wrapping services
│   │   ├── vpn_manager.dart
│   │   ├── server_manager.dart
│   │   ├── settings_manager.dart
│   │   └── persistence_manager.dart
│   ├── models/                # immutable data structures
│   ├── pages/                 # full-screen UI only
│   ├── services/              # business logic, platform integration
│   ├── widgets/               # reusable UI components
│   └── main.dart
├── test/
│   ├── globals/
│   └── services/
├── windows/
│   └── runner/resources/      # sing-box.exe, wintun.dll, app_icon.ico (not in VCS)
├── assets/images/
├── installer.iss              # Inno Setup script for distribution installer
├── pubspec.yaml
└── analysis_options.yaml
```

### Layer boundaries (no cyclic deps)

| Layer | Responsibility |
|-------|---------------|
| `pages/` | Full-screen UI, no business logic |
| `widgets/` | Reusable UI components only |
| `managers/` | High-level orchestrators, coordinate services |
| `services/` | Business logic, platform API calls |
| `models/` | Immutable typed data |
| `globals/` | App-wide state (`AppState`), config, theme |

---

## Stack

- Flutter stable, Dart SDK >=3.2.0
- Windows desktop only (sing-box backend requires Win32)
- Provider (ChangeNotifier) — `AppState` is the single source of truth
- Dio — HTTP (subscriptions, IP lookup, Clash API)
- shared_preferences — persistence
- win32 + ffi — native Win32 calls, sing-box DLL integration
- go_router — navigation
- system_tray + window_manager — tray and window lifecycle
- sing-box v1.13.x — VPN core (ships as `sing-box.exe` + `wintun.dll` beside the binary)

---

## VPN Architecture

**Two runtime modes:**

| Mode | How | UAC |
|------|-----|-----|
| TUN (default) | sing-box via in-process DLL (`SingboxFfi`), TUN adapter `InputVPNTun` | Once at first launch (manifest `requireAdministrator`) |
| Proxy / SOCKS5 | Same DLL, no TUN, no adapter | Never |

**Key classes:**

- `SingBoxVpnService` — top-level VPN backend; owns connect/disconnect/reconnect lifecycle
- `SingBoxProcessFfi` — manages sing-box DLL calls, work directory, log file
- `SingboxFfi` — raw FFI bindings to `libsingbox.dll`
- `SingBoxConfigBuilder` — generates `config.json` for sing-box from `ParsedConfig`
- `ClashApiClient` — polls `127.0.0.1:9090` for stats and connection confirmation
- `NetworkUtils` — Win32 adapter cleanup, DNS reset (used on disconnect and window close)

**Connection lifecycle:**
1. `AppState.toggleConnection()` → `SingBoxVpnService.connect(parsedConfig)`
2. Config generated → DLL started → Clash API polled until ready → `Connected` emitted
3. On window close: 10 s timeout for disconnect, then `NetworkUtils.globalCleanup()` fallback

**Crash watchdog:** `SingBoxVpnService` auto-reconnects up to 3 times on unexpected DLL exit.

**Config persistence:** `AppState` serializes servers/configs/parsedConfigs to `SharedPreferences` as JSON on every mutation.

---

## Build & Release

### Prerequisites (local)

- Flutter stable, desktop enabled
- Visual Studio 2022 with "Desktop development with C++" workload
- `sing-box.exe` (v1.13.x, Win64) + `wintun.dll` placed in `windows/runner/resources/` — **not committed to VCS**
- Inno Setup 6 (for installer builds)

### Commands

```powershell
flutter pub get
flutter analyze --fatal-infos
flutter test
flutter build windows --release
iscc installer.iss                # → Output\InputVPN-Setup.exe
```

### Version bump checklist

When changing `version:` in `pubspec.yaml`:
- `installer.iss` → `AppVersion=`
- `lib/pages/home_page.dart` → version string in `_SidebarStatus`
- `lib/pages/settings_screen.dart` → `_currentVersion`

### CI/CD

- `ci.yaml` — runs `flutter analyze` + `flutter test` on every push/PR
- `release.yaml` — triggers on `v*` tag; builds Windows release, packages installer, publishes GitHub Release

---

## Engineering Principles

### Simplicity first

- Minimal change, maximum effect.
- `if/else` over unnecessary patterns.
- DRY is not absolute — duplication beats harmful abstraction.
- Remove complexity instead of documenting it.

### Type safety

- No `dynamic`. No gratuitous `as` casts.
- `final` by default. `var` only when type is obvious from RHS.
- Nullable types are intentional — treat them as such.
- `strict-casts`, `strict-inference`, `strict-raw-types` enforced in `analysis_options.yaml`.

### Error handling

- Never silently swallow exceptions. Empty catch blocks are forbidden.
- All Win32/FFI calls must validate return codes.
- Cleanup is guaranteed via `try/finally` or `dispose`.
- Error messages must be actionable.

### Async safety

- No `setState` after `dispose`.
- No concurrent sing-box instances.
- State transitions must be valid under async execution.
- Cancel subscriptions and timers in `dispose`.

### Performance

- No unnecessary widget rebuilds — use `context.select` over `context.watch` where possible.
- Heavy IO/parsing off the UI thread.
- Dispose all streams, listeners, controllers.

### Testing

- New logic → new tests.
- Tests validate real behavior, not snapshots.
- Run `flutter analyze --fatal-infos && flutter test` before committing.
- Do not claim tests passed without running them.

### Comments

Write comments only when the **why** is non-obvious: Win32 quirks, lifecycle edge cases, security assumptions, non-obvious constraints. Do not comment what the code already says.

### Security

- No hardcoded credentials or tokens.
- Never log subscription URLs or auth data.
- Validate all process arguments.
- Minimum required privileges.
- Temporary files must be deleted.

---

## Forbidden

- `// ignore:` without explicit approval
- Empty catch blocks
- Force unwrap (`!`) without strong justification
- Massive unrelated refactors in a fix commit
- Speculative abstractions
- Dead code
- Changing UX without explicit request
- Claiming compilation/tests succeeded without running them

---

## Windows/FFI Rules

- Always release native handles and resources.
- Validate Win32 return codes.
- Avoid leaking processes or temp files.
- UAC elevation flows must fail gracefully.
- Native interactions must be isolated and testable.

---

## VPN-specific Rules

- DNS and routing behavior must be explicit and deterministic.
- Never silently alter routing.
- Connection lifecycle must be deterministic and race-free.
- Config generation must be reproducible and validated.
- Subscription parsing must tolerate malformed input.
- Network failures must produce typed, understandable errors.
