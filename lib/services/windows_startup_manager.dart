import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Manages Windows auto-launch on startup via HKCU registry Run key.
///
/// All public methods are no-ops on non-Windows platforms so the rest of
/// the app can call them unconditionally.
class WindowsStartupManager {
  static const _runKey =
      r'Software\Microsoft\Windows\CurrentVersion\Run';
  static const _appName = 'InputVPN';

  /// Opens the registry key with [access], executes [action], then closes it.
  static void _withRegistryKey(int access, void Function(int hKey) action) {
    final phKey = calloc<HANDLE>();
    try {
      final openResult = RegOpenKeyEx(
        HKEY_CURRENT_USER,
        _runKey.toNativeUtf16(),
        0,
        access,
        phKey,
      );
      if (openResult != ERROR_SUCCESS) {
        throw StateError('Failed to open registry key (error $openResult)');
      }
      action(phKey.value);
    } finally {
      if (phKey.value != 0) {
        RegCloseKey(phKey.value);
      }
      free(phKey);
    }
  }

  /// Whether the app is registered to launch on Windows startup.
  static bool isEnabled() {
    if (!Platform.isWindows) return false;
    try {
      final pcbData = calloc<DWORD>();
      try {
        var found = false;
        _withRegistryKey(KEY_READ, (hKey) {
          final queryResult = RegQueryValueEx(
            hKey,
            _appName.toNativeUtf16(),
            nullptr,
            nullptr,
            nullptr,
            pcbData,
          );
          if (queryResult == ERROR_SUCCESS) found = true;
        });
        return found;
      } finally {
        free(pcbData);
      }
    } catch (_) {
      return false;
    }
  }

  /// Enable auto-launch on Windows startup.
  static void enable(String exePath) {
    if (!Platform.isWindows) return;
    _withRegistryKey(KEY_WRITE, (hKey) {
      final value = '"$exePath"'.toNativeUtf16();
      final setResult = RegSetValueEx(
        hKey,
        _appName.toNativeUtf16(),
        0,
        REG_SZ,
        value.cast<BYTE>(),
        (value.length + 1) * 2,
      );
      if (setResult != ERROR_SUCCESS) {
        throw StateError('Failed to set registry value (error $setResult)');
      }
    });
  }

  /// Disable auto-launch on Windows startup.
  static void disable() {
    if (!Platform.isWindows) return;
    _withRegistryKey(KEY_WRITE, (hKey) {
      final delResult = RegDeleteValue(
        hKey,
        _appName.toNativeUtf16(),
      );
      if (delResult != ERROR_SUCCESS && delResult != ERROR_FILE_NOT_FOUND) {
        throw StateError('Failed to delete registry value (error $delResult)');
      }
    });
  }
}
