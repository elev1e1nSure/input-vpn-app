# AI Context — Input VPN

## 1. Правила коммитов (Conventional Commits)

**Формат:**
```
<type>(<scope>): <subject>
```

**Типы:**
| Тип | Когда использовать |
|-----|------------------|
| `feat` | Новая функциональность |
| `fix` | Исправление бага |
| `docs` | Изменения в документации |
| `style` | Форматирование, отступы, запятые (без изменения логики) |
| `refactor` | Рефакторинг кода (без новых фич и без фиксов) |
| `test` | Добавление/исправление тестов |
| `chore` | Служебные задачи: линтер, CI/CD, зависимости, конфиги |

**Scopes:**
- `lint` — analysis_options, исправление warning'ов
- `test` — unit-тесты
- `ci` — GitHub Actions workflow
- `parser` — VpnUrlParser
- `config` — SingBoxConfigBuilder
- `persist` — AppState persistence helpers
- `dio` — DioFactory
- `ui` — экраны, виджеты
- `core` — критичные сервисы (VPN, процесс, API)

**Примеры:**
```
chore(lint): add strict analysis_options and fix all warnings
feat(test): add AppState persist and DioFactory unit tests
chore(ci): add GitHub Actions for PR checks, Windows build and release
fix(ci): use latest stable Flutter instead of pinned version
refactor(parser): extract common URI parsing helper
```

---

## 2. Структура проекта

```
input-vpn-app/
├── .github/workflows/          # CI/CD (GitHub Actions)
│   ├── ci.yaml                 # PR/push: analyze + test + Windows build artifact
│   └── release.yaml            # Tag push: release build + GitHub Release
├── lib/
│   ├── globals/
│   │   ├── app_state.dart      # Central state (Provider): VPN, settings, persistence
│   │   ├── shared_prefs.dart   # Global SharedPreferences instance
│   │   └── themes.dart         # Light / dark ThemeData
│   ├── l10n/
│   │   └── app_strings.dart    # Localization (RU/EN)
│   ├── models/
│   │   ├── connection_failure.dart  # Typed VPN errors
│   │   ├── connection_status.dart     # ConnectionStatus sealed class
│   │   ├── parsed_config.dart         # ParsedConfig DTO
│   │   ├── proxy_type.dart            # ProxyType enum
│   │   └── vpn_stats.dart             # VpnStats throughput data
│   ├── pages/
│   │   ├── home_page.dart            # Main screen: connect button, stats, mode toggle
│   │   ├── settings_screen.dart      # Basic settings: DNS, dark mode, auto-launch
│   │   ├── advanced_settings_screen.dart  # Proxy mode, port, stub features
│   │   ├── servers_screen.dart       # Server list + add config
│   │   └── add_config_screen.dart    # Manual / QR / subscription input
│   ├── services/
│   │   ├── singbox_vpn_service.dart   # VpnService impl: lifecycle, status, stats
│   │   ├── singbox_process.dart       # Spawns sing-box.exe with UAC elevation
│   │   ├── singbox_config_builder.dart # Builds sing-box JSON from ParsedConfig
│   │   ├── vpn_url_parser.dart        # Parses vless/vmess/trojan/ss/hy2 links
│   │   ├── subscription_service.dart  # Downloads and parses subscription URLs
│   │   ├── clash_api_client.dart      # REST client for sing-box Clash API
│   │   ├── dio_factory.dart           # Centralized Dio instances
│   │   ├── windows_startup_manager.dart # HKCU Run key for auto-launch
│   │   └── vpn_service.dart           # Abstract VpnService + MockVpnService
│   ├── widgets/
│   │   └── settings_tiles.dart        # Reusable settings UI components
│   └── main.dart                      # Entry point, initializes sharedPrefs
├── test/
│   ├── globals/
│   │   └── app_state_persist_test.dart  # Tests for AppState persist helpers
│   ├── services/
│   │   ├── dio_factory_test.dart        # DioFactory timeout/UA tests
│   │   ├── singbox_config_builder_test.dart
│   │   └── vpn_url_parser_test.dart     # Parser + SubscriptionService tests
├── analysis_options.yaml            # Strict lints: strict-casts, strict-raw-types, strict-inference
├── pubspec.yaml                     # Dependencies: provider, dio, shared_preferences, win32, ffi
└── windows/                         # Windows runner + CMake
```

---

## 3. Текущее состояние проекта

### Архитектура
- **State management:** Provider (`AppState` — `ChangeNotifier`)
- **Backend:** sing-box.exe (TUN / SOCKS5 proxy mode)
- **Platform:** Windows desktop (Win32 API через FFI)
- **Persistence:** `SharedPreferences` (global `sharedPrefs` instance)
- **HTTP:** Dio (централизовано через `DioFactory`)

### Что реализовано
- [x] Парсинг ссылок: VLESS, VMess, Trojan, Shadowsocks, Hysteria2
- [x] Построение sing-box JSON-конфигурации (`SingBoxConfigBuilder`)
- [x] Запуск/остановка VPN с UAC-элевацией (`SingBoxProcess`)
- [x] Clash API клиент (трафик, версия, latency)
- [x] Подписки (base64/plain text + userinfo)
- [x] UI: Home, Servers, Settings, Advanced Settings
- [x] Темная тема, авто-запуск Windows, авто-подключение
- [x] Режим прокси (SOCKS5) vs полный TUN VPN
- [x] Линтер: `analysis_options.yaml` со strict mode (0 warnings)
- [x] Unit-тесты: `VpnUrlParser`, `SingBoxConfigBuilder`, `DioFactory`, `AppState` persist
- [x] CI/CD: GitHub Actions (analyze + test + Windows artifact + release)

### Последние коммиты
```
4c4c5bb feat(ui): add app icon asset and Windows ICO with multi-resolution
a25e3ad fix(ci): use latest stable Flutter instead of pinned version
61fe6b7 fix(ci): bump Flutter version to 3.29.x for shared_preferences compat
a39f223 chore(ci): add GitHub Actions for PR checks, Windows build and release
27b9932 feat(test): add AppState persist and DioFactory unit tests
25941d9 chore(lint): add strict analysis_options and fix all warnings
d31e973 refactor: deep cleanup — security, DRY, structure
```

---

## 4. Кодекс инженера

### Философия
Пиши production-grade код:
- предсказуемый
- типобезопасный
- минималистичный
- тестируемый
- удобный для review и поддержки

Избегай overengineering, giant abstractions и pseudo-clean-code fanfiction. Минимальное изменение, максимальный эффект.

### Принципы

#### 1. Ноль компромиссов с качеством
- Никаких «пока сойдёт», «временно так оставим», «потом поправим». Временные решения — навсегда.
- Каждый метод, каждый класс, каждый файл должен выглядеть так, будто его ревьюили 5 человек.
- Если видишь запах — устраняй. Не объясняй, почему его можно оставить. Просто исправляй.

#### 2. Простота — высшая форма интеллекта
- Если решение требует комментария «здесь сложно, но работает» — оно неправильное.
- Предпочитай прямолинейность хитроумным абстракциям. `if/else` лучше непонятного паттерна.
- DRY не ради DRY. Не выделяй общий код, если это делает логику запутаннее.

#### 3. Типобезопасность и строгость
- Избегай `dynamic` и необоснованных `as`.
- `var` разрешён, когда тип очевиден из правой части выражения. `final dio = Dio(options);` читается лучше, чем `final Dio dio = Dio(options);`.
- `strict-casts`, `strict-raw-types`, `strict-inference` — не правила линтера, а мантра.
- `null` — враг. `Nullable` должен быть осознанным выбором, а не дефолтом.

#### 4. Обработка ошибок — первоклассный гражданин
- Не подавляй исключения. Не ловишь? Добавь комментарий, почему.
- Win32 API, FFI, процессы — всё с проверкой кодов возврата и гарантированным cleanup (try/finally, `using`, RAII).
- Пользователь никогда не увидит `Null check operator used on a null value`.

#### 5. Тесты — не опция, а обязанность
- Новый код = новые тесты. Рефакторинг = существующие тесты должны проходить.
- Не пиши тесты «чтобы было». Пиши тесты, которые ловят реальные баги.
- `flutter test` и `flutter analyze --fatal-infos` — обязательный gate перед любым коммитом.

#### 6. Минимализм
- Не добавляй файлы, которые не нужны. Не добавляй зависимости ради одной функции.
- Не меняй форматирование существующего кода без причины.

#### 7. Комментарии
- Не комментируй очевидное.
- Комментарии допустимы для platform-specific behavior, Win32 quirks, security assumptions и нетривиальных архитектурных решений.

#### 8. Безопасность по умолчанию
- Никаких хардкодов путей, credentials, API-ключей.
- Registry, файловая система, процессы — всё с минимально необходимыми правами.
- Любой ввод от пользователя считается враждебным до доказательства обратного.

#### 9. Архитектурная целостность
- Не ломай абстракции. `lib/services/` — чистая бизнес-логика, `lib/pages/` — только UI, `lib/models/` — только данные.
- Не создавай циклических зависимостей. Если возникла — разрывай через абстракцию или DI.
- UI state локален для виджетов. Бизнес-состояние хранится только в `Provider` / `AppState`.
- `AppState` — основной source of truth для пользовательского состояния.

#### 10. Производительность и ресурсы
- Не создавать лишние rebuild'ы.
- Stream / subscription / listener всегда должны освобождаться.
- IO и parsing не должны блокировать UI thread.
- Любой polling должен иметь justification.
- Минимизировать startup latency и memory footprint.

#### 11. VPN и network security
- Никогда не логировать credentials, subscription URLs или tokens.
- Конфиги sing-box должны храниться минимально необходимое время.
- Temporary files обязаны удаляться.
- Любая external process execution должна валидировать аргументы.
- DNS / leak-sensitive настройки изменять только явно.

### Процесс работы
1. **Анализируй** — пойми корень проблемы, а не симптом. Прочитай весь файл, не только строку с ошибкой.
2. **Планируй** — подумай о побочных эффектах. Изменение в `app_state.dart` может сломать 3 экрана.
3. **Реализуй** — минимальное изменение, максимальный эффект. Single-responsibility в каждом коммите.
4. **Проверяй** — `flutter analyze`, `flutter test`. Если ломается — чини, не отключай правила.
5. **Документируй** — commit message по Conventional Commits. Если изменение сложное — добавь пояснение в PR.

### Запрещено навсегда
- `// ignore:` без письменного разрешения пользователя.
- `print()` в production-коде. Используй `debugPrint` или логгер.
- `catch (e) {}` — пустые catch-блоки.
- `!` (force unwrap) без обоснования.
- Дублирование кода ради «быстрее написать».
- Изменение логики / UX без согласования с пользователем.
- Создание helper-скриптов, которые живут один раз и забываются.

---

## 5. Инструкции для AI-ассистента

### Технические требования
1. **Всегда** следовать Conventional Commits (см. раздел 1).
2. **Всегда** запускать `flutter analyze` после изменений — 0 issues.
3. **Всегда** запускать `flutter test` после изменений — все тесты проходят.
4. **Provider pattern:** `AppState.of(context)` (без `listen: true`, т.к. это default).
5. **Doc comments:** экранировать `<` и `>` через `[...]` или backticks, чтобы избежать `unintended_html_in_doc_comment`.
6. **Windows-specific:** код с Win32 API (`win32`, `ffi`) должен иметь корректную обработку ошибок и cleanup ресурсов.
7. **Производительность:** анализировать лишние rebuild'и, освобождать подписки, не блокировать UI thread тяжёлым IO.

### Технический стек
- Flutter stable (latest)
- Dart SDK >=3.9.0 (требование `shared_preferences`)
- Платформа: Windows desktop
- Зависимости: `provider`, `dio`, `shared_preferences`, `win32`, `ffi`, `path_provider`, `go_router`
