# Input VPN
[<kbd>  Читать на русском  </kbd>](README.ru.md)

> A lightweight Windows desktop VPN client built with **Flutter** and powered by **sing-box**.

<p align="center">
  <img src="screenshots/main.png" width="400" alt="Main Screen" />
  <img src="screenshots/settings.png" width="400" alt="Settings Screen" />
</p>

<p align="center">
  <a href="https://github.com/elev1e1nSure/input-vpn-app/releases/latest">
    <img src="https://img.shields.io/badge/Download-Latest%20Release-blue?style=for-the-badge&logo=github" alt="Download" />
  </a>
</p>

## Overview

**Input VPN** is a free, open-source VPN client for Windows 10/11. It connects using the modern **sing-box** core and supports the most popular proxy protocols out of the box. No extra software required — just add your config and connect.

## Features

- **Protocols** — VLESS, VMess, Trojan, Shadowsocks (incl. REALITY).
- **System VPN (TUN)** — full-system tunnel; UAC is requested **once** on first launch and never again.
- **SOCKS5 Proxy mode** — local proxy on `127.0.0.1:11080`, no admin rights needed.
- **Subscriptions** — add a single link or an entire subscription URL (Base64 / plain text).
- **Server management** — latency display, selection, rename, edit, delete.
- **Live stats** — real-time upload / download speed, total traffic, and ping on the main screen.
- **Crash watchdog** — auto-reconnects if the VPN core exits unexpectedly.
- **Event log** — timestamped connection history and error log.
- **Split tunneling** — choose which apps bypass the VPN (Windows settings).
- **DNS presets** — switch between Cloudflare, Google, Quad9, or custom DNS.
- **Tray mode** — minimize to system tray instead of closing.
- **Themes & language** — dark / light mode, Russian / English interface.
- **Auto update check** — built-in check for new releases via GitHub.

## Download & Install

1. Go to **[Releases](https://github.com/elev1e1nSure/input-vpn-app/releases/latest)**.
2. Download `InputVPN-Setup.exe`.
3. Run the installer and follow the prompts.
4. Launch **Input VPN** from the Start Menu or Desktop.

## Quick Start

1. **Add a server**
   - Open the **Servers** tab.
   - Paste a single link (`vless://...`, `vmess://...`, `ss://...`, `trojan://...`) or a subscription URL.
2. **Select & connect**
   - Tap the server you want to use.
   - Press the big **power button** on the home screen.
   - On the very first launch the app registers a background task — you will see **one UAC prompt**. After that, connects are silent.
3. **Done!**
   - Your public IP, ping, and live traffic stats appear on the main screen.

## Settings

| Setting | What it does |
|---------|-------------|
| **SOCKS Debug Mode** | Runs sing-box as a local SOCKS5 proxy instead of system TUN. No UAC needed. |
| **Minimize to Tray** | Closing the window hides the app to the system tray instead of quitting. |
| **Split Tunneling** | Pick apps that should bypass the VPN tunnel. |
| **DNS** | Choose a preset (Cloudflare, Google, Quad9) or enter custom DNS servers. |
| **Auto-Update Subscription** | Periodically refreshes your subscription URL in the background. |
| **Dark Mode** | Toggle between light and dark themes. |
| **Language** | Switch between English and Русский. |

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "VPN engine failed to start" | Make sure `sing-box.exe` is bundled with the app (it ships inside the installer). |
| UAC prompt on every connect | Should only happen on the very first launch. If it repeats, delete `%APPDATA%\inputvpn\Input VPN\` to reset app state. |
| No traffic / 0 KB/s | The server may be offline or the config has an invalid UUID/SNI. Test the same config in another client. |
| App won't start / crashes on launch | Delete `%APPDATA%\inputvpn\Input VPN\singbox\` to clear corrupted config and logs. |
| Latency shows "—" | The server is unreachable or the ICMP ping is blocked by the remote host. |

## System Requirements

- Windows 10 version 1809+ or Windows 11
- 64-bit (x64) architecture
- Administrator rights (once, on first launch only)

## For Developers

### Prerequisites

- Flutter stable with Windows desktop support enabled
- Visual Studio 2022 — **"Desktop development with C++"** workload required
- `sing-box.exe` (v1.13.x, Win64) + `wintun.dll` placed in `windows/runner/resources/`
- Inno Setup 6 — only needed to build the installer

### Build

```powershell
flutter pub get
flutter build windows --release
# Portable build: build\windows\x64\runner\Release\
```

### Installer

```powershell
iscc installer.iss
# Output: Output\InputVPN-Setup.exe
```

See [`CLAUDE.md`](./CLAUDE.md) for architecture overview, coding conventions, and engineering rules.

## License

MIT
