import 'dart:io';

import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

/// Manages the Windows system tray icon, tooltip, and context menu.
class TrayManager {
  static final SystemTray _systemTray = SystemTray();
  static bool _initialized = false;

  static Future<void> init() async {
    if (!Platform.isWindows || _initialized) return;

    await _systemTray.initSystemTray(
      title: 'Input VPN',
      iconPath: Platform.isWindows ? '' : 'assets/images/app_icon.png',
      toolTip: 'Input VPN',
    );

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
          await windowManager.close();
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
