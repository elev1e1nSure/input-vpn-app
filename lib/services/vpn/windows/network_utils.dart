import 'dart:io';
import 'package:flutter/foundation.dart';

/// Utilities for Windows network management (TUN, DNS, routes).
class NetworkUtils {
  /// The name of the TUN interface used in SingBoxConfigBuilder.
  static const String tunInterfaceName = 'InputVPNTun';

  /// Removes leftover network state created by THIS app: routes and the TUN
  /// adapter named `InputVPN*`. A single PowerShell invocation is used to
  /// minimise process-startup overhead.
  ///
  /// Important: this intentionally does NOT touch DNS on physical adapters.
  /// The app runs sing-box in TUN mode with `auto_route`/`strict_route`/
  /// `hijack-dns`, so DNS is handled entirely inside sing-box via the TUN
  /// device — the app never reconfigures physical-NIC DNS. Removing the
  /// `InputVPN*` adapter is sufficient; blanket-resetting every adapter to
  /// DHCP would clobber users' manually-configured static DNS that the app
  /// never changed.
  static Future<void> globalCleanup() async {
    if (!Platform.isWindows) return;

    debugPrint('NetworkUtils: starting scoped cleanup (InputVPN* only)...');
    const script = r'''
      Get-NetRoute | Where-Object { $_.InterfaceAlias -like "InputVPN*" } |
        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
      Get-NetAdapter | Where-Object { $_.Name -like "InputVPN*" } |
        Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue
    ''';
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);
      debugPrint('NetworkUtils: scoped cleanup finished.');
    } on Exception catch (e) {
      debugPrint('NetworkUtils: cleanup error: $e');
    }
  }

  /// Force deletes the Wintun/TUN interface (standalone helper, rarely needed
  /// directly — prefer [globalCleanup], which also clears leftover routes).
  static Future<void> deleteTunInterface() async {
    debugPrint('NetworkUtils: deleting TUN interface $tunInterfaceName...');
    try {
      await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'Get-NetAdapter | Where-Object { $_.Name -like "InputVPN*" } | Remove-NetAdapter -Confirm:$false -ErrorAction SilentlyContinue',
      ]);
    } on Exception catch (e) {
      debugPrint('NetworkUtils: deleteTunInterface error: $e');
    }
  }

  /// Checks if the TUN interface currently exists.
  static Future<bool> doesTunInterfaceExist() async {
    final result = await Process.run(
        'netsh', ['interface', 'show', 'interface', 'name=$tunInterfaceName']);
    return result.exitCode == 0;
  }

  /// Checks if the TUN interface is in a healthy state.
  /// Returns false if the interface exists but is in a broken state
  /// (e.g., "Up" but without IP, or stuck in Windows).
  static Future<bool> isTunHealthy() async {
    if (!Platform.isWindows) return true;

    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        '''
        Get-NetAdapter | Where-Object { \$_.Name -like "InputVPN*" } | ForEach-Object {
          \$adapter = \$_
          \$ipConfig = Get-NetIPAddress -InterfaceAlias \$_.Name -ErrorAction SilentlyContinue
          if (\$adapter.Status -eq "Up" -and (!\$ipConfig -or \$ipConfig.Count -eq 0)) {
            Write-Output "UNHEALTHY"
          } elseif (\$adapter.Status -eq "Disconnected" -and \$ipConfig) {
            Write-Output "UNHEALTHY"
          } else {
            Write-Output "HEALTHY"
          }
        }
        ''',
      ]);

      final output = (result.stdout as String).trim();
      return !output.contains('UNHEALTHY');
    } on Exception catch (e) {
      debugPrint('NetworkUtils: isTunHealthy error: $e');
      return true;
    }
  }

  /// Performs cleanup if the TUN interface is unhealthy.
  /// Returns true if cleanup was performed, false otherwise.
  static Future<bool> cleanupIfUnhealthy() async {
    if (!Platform.isWindows) return false;

    final isHealthy = await isTunHealthy();
    if (isHealthy) {
      debugPrint('NetworkUtils: TUN interface is healthy, no cleanup needed');
      return false;
    }

    debugPrint('NetworkUtils: TUN interface is unhealthy, performing cleanup');
    await globalCleanup();
    return true;
  }
}
