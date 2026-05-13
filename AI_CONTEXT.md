# AI Context — Input VPN

---

## 1. Commit Convention (Conventional Commits)

### Format

```text
<type>(<scope>): <subject>
```

### Types

| Type | Usage |
|------|-------|
| `feat` | New functionality |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Formatting only, no logic changes |
| `refactor` | Internal refactor without feature/fix |
| `test` | Tests added or updated |
| `chore` | Tooling, CI/CD, configs, dependencies |

### Scopes

- `lint` — analysis_options, warning cleanup
- `test` — unit/widget tests
- `ci` — GitHub Actions workflows
- `parser` — VpnUrlParser
- `config` — SingBoxConfigBuilder
- `persist` — persistence helpers
- `dio` — DioFactory
- `ui` — pages/widgets/themes
- `core` — VPN/process/API/services
- `security` — credentials, validation, sandboxing
- `perf` — rebuilds, memory, startup, async optimization

### Examples

```text
chore(lint): enable strict analysis options and fix warnings
feat(ui): add animated connection status indicator
fix(core): prevent duplicate sing-box process launch
refactor(parser): extract shared URI parsing utilities
test(config): add sing-box DNS routing tests
chore(ci): add Windows release workflow
```

---

## 2. Project Structure

```
input-vpn-app/
├── .github/workflows/
│   ├── ci.yaml
│   └── release.yaml
├── lib/
│   ├── globals/
│   │   ├── app_state.dart
│   │   ├── shared_prefs.dart
│   │   └── themes.dart
│   ├── l10n/
│   │   └── app_strings.dart
│   ├── models/
│   ├── pages/
│   ├── services/
│   ├── widgets/
│   └── main.dart
├── test/
├── analysis_options.yaml
├── pubspec.yaml
└── windows/
```

### Architecture boundaries

- `pages/` → UI only
- `widgets/` → reusable UI components only
- `services/` → business logic and platform integration
- `models/` → immutable typed data structures
- `globals/` → app-wide state/config/theme

**No cyclic dependencies between layers.**

---

## 3. Current Stack

- Flutter stable
- Dart SDK >=3.9.0
- Windows desktop
- Provider (ChangeNotifier)
- Dio
- shared_preferences
- win32 + ffi
- go_router
- sing-box backend

---

## 4. Engineering Principles

### 4.1 Production-grade mindset

Write code that is:

- predictable
- type-safe
- maintainable
- testable
- review-friendly
- minimal without being cryptic

Prefer clarity over cleverness.

**Avoid:**

- overengineering
- giant abstractions
- speculative architecture
- pseudo-clean-code fanfiction

**Minimal change. Maximum effect.**

### 4.2 Simplicity

- Prefer explicit code over magic abstractions.
- `if/else` is often better than unnecessary patterns.
- DRY is not absolute. Duplication is acceptable if abstraction harms readability.
- Remove complexity instead of documenting it away.

### 4.3 Type safety

- Avoid `dynamic`.
- Avoid unnecessary `as`.
- `var` is acceptable when the type is obvious from the right side.
- Prefer `final` by default.
- Treat nullable types as intentional design decisions.

**Strict analyzer rules are mandatory:**

- `strict-casts`
- `strict-inference`
- `strict-raw-types`

### 4.4 Error handling

- Never silently swallow exceptions.
- Empty catch blocks are forbidden.
- All process/Win32/FFI interactions must validate results.
- Cleanup must be guaranteed (try/finally, disposals, handle cleanup).
- Error messages must contain actionable context.

**The user must never see:**

```
Null check operator used on a null value
```

### 4.5 Testing

- New logic requires tests.
- Refactors must preserve passing tests.
- Tests must validate real behavior and edge cases.
- Avoid meaningless snapshot-style tests.

**Before commits:**

```bash
flutter analyze --fatal-infos
flutter test
```

**Do not claim tests/analyze passed unless they were actually executed.**

### 4.6 Minimal diffs

- Do not modify unrelated code.
- Do not perform drive-by refactors.
- Do not rename files/classes/functions without necessity.
- Keep commits focused and reviewable.
- Prefer local changes over broad rewrites.

### 4.7 Comments

- Do not comment obvious code.
- Comments are acceptable for:
  - Win32 quirks
  - security assumptions
  - lifecycle edge cases
  - non-obvious architectural constraints
  - platform-specific behavior

**Good code explains what. Comments explain why.**

### 4.8 Security

- Never hardcode credentials, tokens or secrets.
- Never log credentials or subscription URLs.
- Treat all external/user input as hostile.
- Validate all process arguments.
- Use minimum required privileges.
- Temporary files must be deleted.
- Sensitive config data should exist only as long as required.

### 4.9 Architecture integrity

- UI state belongs inside widgets.
- Application/business state belongs in `AppState`.
- Do not mix UI and business logic.
- Avoid service-to-service tight coupling.
- Break cycles through abstractions or dependency injection.
- Preserve existing architectural boundaries.

### 4.10 Performance

- Avoid unnecessary rebuilds.
- Dispose all streams/listeners/subscriptions/controllers.
- Heavy IO/parsing must not block the UI thread.
- Polling requires explicit justification.
- Minimize startup latency and memory usage.
- Avoid excessive allocations inside rebuilds.

### 4.11 Async and concurrency safety

- Prevent race conditions during connect/disconnect.
- Never allow multiple sing-box instances simultaneously.
- State transitions must remain valid under async execution.
- Async operations should be cancellation-safe where possible.
- Avoid stale state updates after widget/service disposal.

### 4.12 UX consistency

- Do not change UX behavior without explicit request.
- Existing navigation flow is considered stable API.
- Preserve hotkeys and expected interactions.
- New UI must match the current visual language.

### 4.13 Logging

- Logs must be useful, concise and actionable.
- No noisy debug spam.
- Logging must not expose sensitive data.
- Logging should not negatively affect performance.

**Use:**

- `debugPrint`
- structured logging

**Avoid:**

- `print();`

### 4.14 Reliability and honesty

- Do not invent APIs or framework capabilities.
- Verify existing signatures before modifying code.
- Do not claim compilation succeeded if it was not verified.
- Do not fabricate test results.
- If something is uncertain, state it explicitly.

---

## 5. Flutter/Dart Conventions

### State management

- Use Provider consistently.
- `AppState` is the primary source of truth.
- Avoid unnecessary `setState`.
- Keep rebuild scopes minimal.

### Widget design

- Prefer small composable widgets.
- Avoid giant `build` methods.
- Extract widgets only when it improves clarity/reuse.

### Async UI

- Never call `setState` after `dispose`.
- Handle loading/error/empty states explicitly.

### Documentation comments

Escape `<` and `>` properly in doc comments:

```dart
/// Returns a `List<String>`.
```

Avoid unintended HTML warnings.

---

## 6. Windows/FFI Rules

- Always release native handles/resources.
- Validate Win32 return codes.
- Avoid leaking processes or temporary files.
- UAC elevation flows must fail gracefully.
- Native interactions must be isolated and testable where possible.

---

## 7. VPN-specific Rules

- DNS/leak-sensitive behavior must be explicit.
- Never silently alter routing behavior.
- Connection lifecycle must remain deterministic.
- Config generation must be reproducible and validated.
- Subscription parsing must tolerate malformed input safely.
- Network failures must produce typed, understandable errors.

---

## 8. Workflow

### 1. Analyze

Understand the root cause before editing.

Read surrounding code before making changes.

### 2. Plan

Think about side effects:

- state
- async behavior
- rebuilds
- persistence
- process lifecycle

### 3. Implement

Prefer the smallest correct solution.

### 4. Verify

Run:

```bash
flutter analyze --fatal-infos
flutter test
```

### 5. Document

Use proper Conventional Commit messages.

Complex behavior changes should include brief rationale.

---

## 9. Forbidden

**Never do these:**

- `// ignore:` without explicit approval
- empty catch blocks
- force unwraps (`!`) without strong justification
- hidden side effects
- massive unrelated refactors
- speculative abstractions
- dead code
- fake TODO-driven architecture
- copy-paste duplication without reason
- changing UX without request

---

## 10. AI Assistant Rules

### The assistant must:

- preserve architecture consistency
- prefer minimal diffs
- avoid unrelated edits
- generate production-ready code
- maintain strict typing
- preserve readability
- prioritize correctness over cleverness
- avoid hallucinated APIs
- avoid unnecessary dependencies

### The assistant must NOT:

- claim tests passed without execution
- invent files/frameworks/APIs
- rewrite working systems without request
- introduce architectural patterns without justification
- silently change behavior
