# README для ДЕБИЛА

Flutter-приложение **Input VPN** для Windows. Стек: Flutter + sing-box (TUN/VPN).
Версия: **1.1.0**.

---

## Что нужно установить один раз

1. **Flutter SDK** — stable channel, desktop support включён.
2. **Visual Studio 2022** — обязательно workload **"Desktop development with C++"**.
3. **Inno Setup** — если будешь собирать `.exe` инсталлятор. Скачать: https://jrsoftware.org/isinfo.php
   - В процессе установки Inno Setup предложит добавить папку в `PATH` — соглашайся.
4. **sing-box** — бинарник `sing-box.exe` версии `v1.13.x` Windows x64.
5. **wintun.dll** — нужна для TUN-режима (обычно идёт в комплекте с sing-box или берётся отдельно).

---

## Где что лежит в проекте

| Путь | Что там |
|------|---------|
| `lib/` | Dart-код приложения |
| `windows/` | Нативный Windows-раннер (C++) |
| `windows/runner/resources/` | Сюда клади `sing-box.exe`, `wintun.dll` и `app_icon.ico` — они автоматом копируются рядом с `.exe` при сборке |
| `build/windows/x64/runner/Release/` | Готовый релизный билд |
| `installer.iss` | Скрипт Inno Setup для создания установщика |
| `pubspec.yaml` | Зависимости Flutter, версия приложения |

---

## Подготовка к сборке

### 1. Положи бинарники VPN-ядра

Копируй в `windows/runner/resources/`:

```powershell
copy C:\Путь\К\sing-box.exe   C:\projects\input-vpn-app\windows\runner\resources\sing-box.exe
copy C:\Путь\К\wintun.dll     C:\projects\input-vpn-app\windows\runner\resources\wintun.dll
copy assets\images\app_icon.ico C:\projects\input-vpn-app\windows\runner\resources\app_icon.ico
```

> Без `sing-box.exe` приложение запустится, но VPN работать не будет.
> Без `wintun.dll` TUN-режим упадёт.

### 2. Подтяни зависимости Flutter

```powershell
flutter pub get
```

---

## Сборка релиза (обычный .exe)

```powershell
flutter build windows --release
```

Готовый файл:

```text
build\windows\x64\runner\Release\input_vpn.exe
```

Всё, что внутри `Release\`, можно переносить на другую машину и запускать — это portable-вариант.

---

## Запуск в режиме разработки (без сборки)

```powershell
flutter run -d windows
```

Или с горячей перезагрузкой и логами:

```powershell
flutter run -d windows --verbose
```

---

## Создание установщика через Inno Setup

### Вариант А: через GUI

1. Открываешь **Inno Setup Compiler**.
2. `File → Open` → выбираешь `installer.iss` из корня проекта.
3. Нажимаешь **Build** (или F9).
4. Готовый установщик появится в папке `Output\` рядом с `installer.iss`:
   ```text
   Output\InputVPN-Setup.exe
   ```

### Вариант Б: через командную строку (если PATH настроен)

```powershell
iscc installer.iss
```

Результат тот же — `Output\InputVPN-Setup.exe`.

### Что делает installer.iss

- Берёт всё содержимое `build\windows\x64\runner\Release\` (включая подпапки).
- Упаковывает в один `.exe` со сжатием LZMA.
- Создаёт ярлык в меню Пуск и на рабочем столе.
- Указывает имя приложения, версию и иконку.

### Обновление версии в установщике

Если меняешь версию в `pubspec.yaml` (например, `version: 1.1.0+6`), не забудь синхронно поправить:

- `installer.iss` → `AppVersion=1.1.0`
- `lib/pages/home_page.dart` → строка `'v1.1.0'` в сайдбаре
- `lib/pages/settings_screen.dart` → константа `_currentVersion`

---

## Полезные команды

| Команда | Зачем |
|---------|-------|
| `flutter pub get` | Обновить/установить пакеты |
| `flutter build windows --release` | Собрать релиз |
| `flutter clean` | Почистить кэш сборки, если что-то пошло не так |
| `flutter run -d windows` | Запустить для отладки |
| `flutter test` | Прогнать unit-тесты |
| `iscc installer.iss` | Собрать установщик Inno Setup |
| `dart fix --apply` | Автоисправление lint-ошибок |
| `flutter build windows --release --verbose` | Сборка с подробным логом |

---

## Типичные проблемы

| Симптом | Причина / Решение |
|---------|-------------------|
| `VPN engine failed to start` | Нет `sing-box.exe` в `windows/runner/resources/` или не та версия. Лог: `%APPDATA%\inputvpn\Input VPN\singbox\app.log`. |
| UAC-запрос при каждом подключении | Должно быть только при первом запуске. Если повторяется — выполни `schtasks /delete /f /tn InputVPNSingBox` и перезапусти приложение. |
| Туннель `InputVPNTun` остаётся в `ncpa.cpl` после закрытия | Пофиксено: при закрытии окна теперь есть таймаут 10 с на disconnect + принудительный `Remove-NetAdapter`. |
| Отключение VPN очень долгое | Пофиксено: cleanup теперь один вызов PowerShell вместо 4 отдельных процессов. |
| Приложение не запускается после сборки | Удали `%APPDATA%\inputvpn\Input VPN\singbox\` — может быть битый `config.json` или `app.log`. |
| Inno Setup не находит `iscc` | Не добавлен в PATH. Или запускай через GUI. |
| Ошибка линковки в CMake | Не установлен Visual Studio 2022 с workload C++ desktop. |

---

## Как устроен VPN под капотом

| Компонент | Роль |
|-----------|------|
| `sing-box.exe` | VPN-ядро. Запускается через Windows Scheduled Task от имени SYSTEM — без UAC после первого запуска. |
| `wintun.dll` | Драйвер TUN-интерфейса для Windows. |
| TUN-адаптер `InputVPNTun` | Виртуальная сетевая карта, видна в `ncpa.cpl`. Создаётся при подключении, удаляется при отключении. |
| Clash API `127.0.0.1:9090` | HTTP API sing-box для мониторинга трафика и пинга. Приложение опрашивает его каждые 2 с. |
| `%APPDATA%\inputvpn\Input VPN\singbox\config.json` | Конфиг sing-box, генерируется автоматически при каждом подключении. |
| `%APPDATA%\inputvpn\Input VPN\singbox\app.log` | Журнал событий приложения. Первое место смотреть при ошибках. |

**Два режима работы:**
- **TUN mode** (по умолчанию) — весь трафик ОС идёт через VPN. UAC запрашивается **один раз** при первом запуске (регистрация Scheduled Task). Адаптер виден в `ncpa.cpl`.
- **Proxy mode** — только SOCKS5 на `127.0.0.1:11080`. Без TUN, без UAC, без адаптера в `ncpa.cpl`. Включается в настройках.

---

## CI / GitHub Actions

В `.github/workflows/release.yaml` настроен автобилд:
- Триггер: push тега `v*`.
- Собирает `flutter build windows --release`.
- Упаковывает в ZIP и публикует в GitHub Releases.

Inno Setup в CI пока не запускается — только ZIP. Если нужен `.exe` установщик, собирай локально или допиши шаг в `release.yaml`.
