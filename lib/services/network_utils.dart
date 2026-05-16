import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilities for Windows network management (TUN, DNS, routes).
class NetworkUtils {
  /// The name of the TUN interface used in SingBoxConfigBuilder.
  static const String tunInterfaceName = 'InputVPNTun';

  /// Performs a deep cleanup of the network state.
  /// Should be called after stop to remove any leftover TUN adapter and
  /// restore DNS. A single PowerShell invocation is used to minimise
  /// process-startup overhead (was previously 3–4 separate spawns).
  static Future<void> globalCleanup() async {
    if (!Platform.isWindows) return;

    debugPrint('NetworkUtils: starting global cleanup...');
    const script = r'''
      Get-NetAdapter | Where-Object { $_.Name -like "InputVPN*" } |
        Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue
      Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        netsh interface ip set dns name="$($_.Name)" source=dhcp 2>$null
      }
    ''';
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);
      debugPrint('NetworkUtils: global cleanup finished.');
    } catch (e) {
      debugPrint('NetworkUtils: cleanup error: $e');
    }
  }

  /// Force deletes the Wintun/TUN interface (standalone helper, rarely needed
  /// directly — prefer [globalCleanup] which also resets DNS).
  static Future<void> deleteTunInterface() async {
    debugPrint('NetworkUtils: deleting TUN interface $tunInterfaceName...');
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'Get-NetAdapter | Where-Object { $_.Name -like "InputVPN*" } |'
            r' Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue',
      ]);
    } catch (e) {
      debugPrint('NetworkUtils: deleteTunInterface error: $e');
    }
  }

  /// Resets DNS settings for ALL interfaces to DHCP (automatic).
  static Future<void> resetAllDns() async {
    debugPrint('NetworkUtils: resetting all DNS to DHCP...');
    const script = r'''
      Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        netsh interface ip set dns name="$($_.Name)" source=dhcp 2>$null
      }
    ''';
    try {
      await Process.run('powershell',
          ['-NoProfile', '-NonInteractive', '-Command', script]);
    } catch (e) {
      debugPrint('NetworkUtils: resetAllDns error: $e');
    }
  }

  /// Checks if the TUN interface currently exists.
  static Future<bool> doesTunInterfaceExist() async {
    final result = await Process.run(
        'netsh', ['interface', 'show', 'interface', 'name=$tunInterfaceName']);
    return result.exitCode == 0;
  }
}
