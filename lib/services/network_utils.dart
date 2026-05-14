import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilities for Windows network management (TUN, DNS, routes).
class NetworkUtils {
  /// The name of the TUN interface used in SingBoxConfigBuilder.
  static const String tunInterfaceName = 'InputVPNTun';

  /// Performs a deep cleanup of the network state.
  /// Should be called before start and after stop.
  static Future<void> globalCleanup() async {
    if (!Platform.isWindows) return;

    debugPrint('NetworkUtils: starting global cleanup...');
    try {
      await Future.wait([
        deleteTunInterface(),
        resetAllDns(),
      ]);
      debugPrint('NetworkUtils: global cleanup finished.');
    } catch (e) {
      debugPrint('NetworkUtils: cleanup error: $e');
    }
  }

  /// Force deletes the Wintun/TUN interface.
  static Future<void> deleteTunInterface() async {
    debugPrint('NetworkUtils: deleting TUN interface $tunInterfaceName...');

    // 1. Try via netsh (standard)
    await Process.run('netsh',
        ['interface', 'delete', 'interface', 'name=$tunInterfaceName']);

    // 2. Try via PowerShell (more powerful for Wintun)
    // This removes the adapter and associated drivers if stuck.
    await Process.run('powershell', [
      '-Command',
      'Get-NetAdapter | Where-Object { \$_.Name -eq "$tunInterfaceName" } | Remove-NetAdapter -Confirm:\$false'
    ]);
  }

  /// Resets DNS settings for ALL interfaces to DHCP (automatic).
  /// This is the most reliable way to restore connectivity if sing-box
  /// failed to restore DNS after a crash.
  static Future<void> resetAllDns() async {
    debugPrint('NetworkUtils: resetting all DNS to DHCP...');

    // We use PowerShell to find all active/up adapters and reset their DNS.
    final script = '''
      Get-NetAdapter | Where-Object { \$_.Status -eq "Up" } | ForEach-Object {
        netsh interface ip set dns name="\$(\$_.Name)" source=dhcp
      }
    ''';

    await Process.run('powershell', ['-Command', script]);
  }

  /// Checks if the TUN interface currently exists.
  static Future<bool> doesTunInterfaceExist() async {
    final result = await Process.run(
        'netsh', ['interface', 'show', 'interface', 'name=$tunInterfaceName']);
    return result.exitCode == 0;
  }
}
