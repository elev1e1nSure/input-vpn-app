# README для себя (и не только)

Flutter-приложение **Input VPN** для Windows. Стек: Flutter + sing-box (TUN/VPN).

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

Если меняешь версию в `pubspec.yaml` (например, `version: 1.0.3+3`), не забудь синхронно поправить:

- `installer.iss` → `AppVersion=1.0.3`

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
| `VPN engine failed to start` | Нет `sing-box.exe` в `windows/runner/resources/` или не та версия. |
| UAC-запрос при каждом подключении | Нормально для TUN-режима. Чтобы избежать — включи SOCKS Debug Mode в настройках. |
| Приложение не запускается после сборки | Удали `%APPDATA%\com.example\Input VPN\` — может быть битый кэш. |
| Inno Setup не находит `iscc` | Не добавлен в PATH. Или запускай через GUI. |
| Ошибка линковки в CMake | Не установлен Visual Studio 2022 с workload C++ desktop. |

---

## CI / GitHub Actions

В `.github/workflows/release.yaml` настроен автобилд:
- Триггер: push тега `v*`.
- Собирает `flutter build windows --release`.
- Упаковывает в ZIP и публикует в GitHub Releases.

Inno Setup в CI пока не запускается — только ZIP. Если нужен `.exe` установщик, собирай локально или допиши шаг в `release.yaml`.
