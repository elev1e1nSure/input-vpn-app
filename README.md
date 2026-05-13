# Input VPN — Windows Desktop Client

Flutter + sing-box VPN client for Windows. Supports VLESS, VMess, Trojan, Shadowsocks (incl. REALITY). Defaults to full TUN system VPN mode.

## Prerequisites

- Windows 10/11
- [Flutter SDK](https://docs.flutter.dev/get-started/install/windows/desktop) (stable channel, desktop support enabled)
- [Visual Studio 2022](https://visualstudio.microsoft.com/) with "Desktop development with C++" workload
- sing-box `v1.13.x` Windows x64 binary (`sing-box.exe`)

## Project Structure

```
lib/
  main.dart                        # Entry point
  globals/
    app_state.dart                 # App-wide state (Provider)
    themes.dart                    # Dark/light themes
  pages/
    home_page.dart                 # Main screen (connect toggle, stats, error banner)
    servers_screen.dart            # Server list & selection
    add_config_screen.dart         # Add single link or subscription
    settings_screen.dart           # Settings incl. SOCKS debug mode
  services/
    singbox_vpn_service.dart       # Real VPN backend (TUN + SOCKS modes)
    singbox_process.dart           # sing-box.exe process management (UAC aware)
    singbox_config_builder.dart    # sing-box 1.13 JSON config generation
    clash_api_client.dart          # Traffic & latency via Clash API
    vpn_url_parser.dart            # vless/vmess/ss/trojan link parser
    subscription_service.dart      # Base64 + plain subscription fetcher
test/                              # Unit tests (config builder, URL parser)
windows/                           # Native runner (portrait 420x820)
```

## Build Instructions

### 1. Place sing-box.exe

Copy `sing-box.exe` (v1.13.x) into the project root. The build script will bundle it next to the app binary:

```powershell
copy C:\Path\To\sing-box.exe C:\projects\input-vpn-app\windows\runner\sing-box.exe
```

> Or place it anywhere and update `lib/services/singbox_process.dart` `_singBoxPath()`.

### 2. Get Flutter dependencies

```powershell
flutter pub get
```

### 3. Build Windows release

```powershell
flutter build windows --release
```

The executable will be at:
```
build\windows\x64\runner\Release\vpn.exe
```

### 4. Run in development mode

```powershell
flutter run -d windows
```

## First-Time Setup

1. Launch the app.
2. Tap the **+** button or go to **My Servers**.
3. Paste a configuration:
   - Single link: `vless://...`, `vmess://...`, `ss://...`, `trojan://...`
   - Subscription URL: any HTTP(S) link with base64/plaintext configs.
4. Select a server and tap the big power button to connect.

> **First connection** will trigger a **UAC prompt** because full TUN mode requires administrator rights.

## Debug / SOCKS Mode

If you need to test without taking over system routes (e.g., alongside another VPN):

1. Open **Settings**.
2. Scroll to **Advanced** → enable **SOCKS Debug Mode**.
3. sing-box will run as a local SOCKS5 proxy on `127.0.0.1:11080` (no UAC).

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "VPN engine failed to start" | Check `sing-box.exe` is present and v1.13+. See log path in error message. |
| UAC prompt every time | Expected for full VPN. To avoid it, enable SOCKS Debug Mode in Settings. |
| No traffic / 0 KB/s | Server may be down or config has wrong SNI/UUID. Verify with another client. |
| App crashes on startup | Delete `%APPDATA%\com.example\Input VPN\singbox\` to clear stale state. |

## Tests

```powershell
flutter test
```

## License

MIT
