import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the Windows system tray icon, tooltip, and context menu.
class TrayManager {
  static final SystemTray _systemTray = SystemTray();
  static bool _initialized = false;
  static AppState? _appState;

  static Future<void> init([AppState? appState]) async {
    _appState = appState;
    if (!Platform.isWindows || _initialized) return;

    String iconPath;
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final pngPath = '$exeDir\\data\\flutter_assets\\assets\\images\\app_icon.png';
      final icoPath = '$exeDir\\app_icon.ico';

      // Try ICO first, then PNG as fallback
      if (File(icoPath).existsSync()) {
        iconPath = icoPath;
        debugPrint('Tray init: using ICO at $iconPath');
      } else if (File(pngPath).existsSync()) {
        iconPath = pngPath;
        debugPrint('Tray init: using PNG at $iconPath');
      } else {
        iconPath = pngPath;
        debugPrint('Tray init: neither ICO nor PNG found, trying PNG path anyway');
      }
    } else {
      iconPath = 'assets/images/app_icon.png';
    }

    debugPrint('Tray init: iconPath=$iconPath');

  final file = File(iconPath);
  debugPrint('Tray init: file exists=${file.existsSync()}, path=$iconPath');

    try {
      await _systemTray.initSystemTray(
        title: 'Input VPN',
        iconPath: iconPath,
        toolTip: 'Input VPN',
      );
      debugPrint('Tray init: success');
    } catch (e) {
      debugPrint('Tray init failed: $e');
      return;
    }

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Show',
        onClicked: (menuItem) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (menuItem) async {
          // Disconnect VPN before closing
          if (_appState?.isConnected ?? false) {
            await _appState?.toggleConnection();
          }
          await windowManager.destroy();
        },
      ),
    ]);
    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show().then((_) => windowManager.focus());
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });

    _initialized = true;
  }

  static Future<void> updateTooltip(String status) async {
    if (!Platform.isWindows || !_initialized) return;
    await _systemTray.setToolTip('Input VPN — $status');
  }

  static Future<void> destroy() async {
    if (!Platform.isWindows || !_initialized) return;
    _initialized = false;
    await _systemTray.destroy();
  }
}
