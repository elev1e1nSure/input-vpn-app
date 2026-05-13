import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Manages Windows auto-launch on startup via HKCU registry Run key.
class WindowsStartupManager {
  static const _runKey =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const _appName = 'InputVPN';

  /// Whether the app is registered to launch on Windows startup.
  static bool isEnabled() {
    try {
      final phKey = calloc<HANDLE>();
      final lResult = RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _runKey.toNativeUtf16(),
        0,
        KEY_READ,
        phKey,
      );
      if (lResult != ERROR_SUCCESS) {
        free(phKey);
        return false;
      }

      final pcbData = calloc<DWORD>()..value = 0;
      final lResult2 = RegQueryValueEx(
        phKey.value,
        _appName.toNativeUtf16(),
        nullptr,
        nullptr,
        nullptr,
        pcbData,
      );

      RegCloseKey(phKey.value);
      free(phKey);
      free(pcbData);

      return lResult2 == ERROR_SUCCESS;
    } catch (_) {
      return false;
    }
  }

  /// Enable auto-launch on Windows startup.
  static void enable(String exePath) {
    try {
      final phKey = calloc<HANDLE>();
      RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _runKey.toNativeUtf16(),
        0,
        KEY_WRITE,
        phKey,
      );

      final value = '"$exePath"'.toNativeUtf16();
      RegSetValueEx(
        phKey.value,
        _appName.toNativeUtf16(),
        0,
        REG_SZ,
        value.cast<BYTE>(),
        (value.length + 1) * 2,
      );

      RegCloseKey(phKey.value);
      free(phKey);
    } catch (_) {}
  }

  /// Disable auto-launch on Windows startup.
  static void disable() {
    try {
      final phKey = calloc<HANDLE>();
      RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _runKey.toNativeUtf16(),
        0,
        KEY_WRITE,
        phKey,
      );

      RegDeleteValue(phKey.value, _appName.toNativeUtf16());
      RegCloseKey(phKey.value);
      free(phKey);
    } catch (_) {}
  }
}
