# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.1] - 2026-06-05

### Added
- CI/CD pipeline with GitHub Actions
- Windows build artifacts upload
- Centralized version management via `AppConstants`
- CHANGELOG.md with automated generation scripts

### Changed
- Replaced all CupertinoIcons and outlined Material Icons with standard Material Icons for Windows compatibility
- Moved Logs screen from sidebar to Settings

### Fixed
- Fixed broken icon rendering (rectangles) on Windows
- Fixed CI failures due to CRLF/LF line endings
- Fixed CI failures due to pre-existing info-level lints
- Fixed unused import warnings

## [1.2.0] - 2026-06-05

### Added
- **Architecture**: Dependency Injection container (`get_it`) in `lib/core/di.dart`
- **Controllers**: Extracted 3 controllers from monolithic `AppState`
  - `VpnConnectionController` — VPN connection lifecycle
  - `SettingsController` — app settings with persistence
  - `NetworkInfoController` — public IP and country code
- **Data Layer**: 
  - `PrefsDataSource` for local preferences
  - `SubscriptionApi` for remote subscription fetching
  - `IpLookupApi` for IP geolocation
- **Error Handling**: `Result<T>` sealed class with `Success`/`Failure`
- **Stability**: Race-condition guards in controllers (`_operationInProgress`, `_isRefreshing`)
- **Design System**: Просека design system with Geist/Inter font, green accent (#4ADE80)
- **Tests**: 58 new tests (84 total), 100% controller coverage
- **CI/CD**: GitHub Actions workflow, Dependabot config

### Changed
- **AppState**: Delegated VPN, settings, and network logic to dedicated controllers
- **Theme**: Replaced iOS blue with Просека green accent
- **Icons**: Liquid fill card, button pulse animation, hover effects

### Removed
- Dead managers: `ServerManager`, `SettingsManager`, `PersistenceManager`, `VpnManager`

### Fixed
- Google Fonts loading errors in tests
- `avoid_catches_without_on_clauses` and `only_throw_errors` pre-existing issues handled in CI

## [1.1.0] - 2026-06-05

### Added
- Sing-box VPN backend integration
- Windows desktop support
- Subscription management
- Auto-connect on boot
- Minimize to tray

### Changed
- Initial stable release with basic VPN functionality

## [1.0.0] - 2026-06-05

### Added
- Initial release
- Basic VPN connection
- Server list management
- Settings screen

---

## Release Checklist

Before releasing a new version:

1. Update `pubspec.yaml` version
2. Update `lib/globals/app_constants.dart` `kAppVersion` and `kBuildNumber`
3. Update `[Unreleased]` section in this file
4. Create new version section with date
5. Run `flutter test` — all tests must pass
6. Run `flutter analyze --fatal-warnings` — no warnings
7. Commit with message: `chore(release): bump version to X.Y.Z+N`
8. Create git tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
9. Push: `git push origin main --tags`
10. GitHub Actions will auto-build Windows artifact
