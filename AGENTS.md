# AGENTS.md - Input VPN

Flutter Windows VPN client powered by sing-box.

This file contains critical project rules only. Communication style and reusable Git commands live in Codex skills.

Use `owner-collaboration` for communication style and autonomy.

## Architecture

* `lib/globals/app_state.dart` owns central app state via `ChangeNotifier`.
* `lib/pages/` contains full-screen UI.
* `lib/widgets/` contains reusable UI components.
* `lib/managers/` coordinates services.
* `lib/services/` contains business logic and platform integration.
* `lib/models/` contains typed data structures.

Keep dependencies one-way:

`UI -> managers/state -> services -> models/platform`

## VPN Core

* Windows desktop only.
* sing-box runs through FFI/DLL integration.
* TUN mode uses adapter `InputVPNTun`.
* Proxy/SOCKS mode must not require TUN adapter changes.
* `SingBoxVpnService` owns connect/disconnect/reconnect lifecycle.
* `SingBoxConfigBuilder` generates sing-box config.
* `NetworkUtils` handles adapter/DNS cleanup.

Do not change VPN lifecycle, routing, DNS, adapter cleanup, config persistence, or sing-box startup behavior unless explicitly asked.

## Critical Rules

* Do not silently alter routing, DNS, proxy behavior, or VPN lifecycle.
* Do not allow concurrent sing-box instances.
* Always release native handles/resources.
* Validate Win32/FFI return codes.
* Do not log subscription URLs, credentials, tokens, or auth data.
* Preserve malformed-input tolerance in subscription/config parsing.
* Do not claim build/tests passed unless the commands were actually run and passed.

## Git Workflow

`main` must stay stable.

Before code changes, create a branch from current `main` unless the user explicitly asks for a direct `main` change.

Branch names:

* `feature/<short-name>` for new functionality.
* `fix/<short-name>` for bug fixes.
* `refactor/<short-name>` for cleanup without behavior changes.
* `experiment/<short-name>` for risky or unclear changes.

Allowed without asking:

* inspect status/log/diff
* create a branch
* edit files
* make local commits on the working branch

Requires explicit user approval:

* merge into `main`
* push to remote
* pull from remote
* force push
* reset hard
* delete branches

Before asking to merge, show:

* `git status`
* changed files summary
* checks run and their result

## Checks

Use the smallest check that matches the change.

```powershell
flutter analyze --fatal-infos
flutter test
flutter build windows --release
```

Documentation-only changes do not require Flutter checks.