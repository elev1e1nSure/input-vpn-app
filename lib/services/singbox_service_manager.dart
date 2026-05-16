import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/services/app_logger.dart';

/// Manages sing-box as a Windows Service so the user only sees UAC
/// once (during installation) instead of on every connection.
///
/// The service is registered with `start= demand` so it does **not**
/// auto-start on boot — the app controls its lifecycle explicitly.
///
/// Requires the app to have called [install] at least once (which
/// triggers one UAC prompt via ShellExecuteEx runas). After that,
/// [start] / [stop] work without elevation.
class SingboxServiceManager {
  static const String serviceName = 'InputVPNService';
  static const String serviceDisplayName = 'Input VPN Service';

  // ── Installation ────────────────────────────────────────────────────────────

  /// Install the Windows Service. Requires elevation — prompts UAC once.
  ///
  /// [exePath] must be the absolute path to `sing-box.exe`.
  /// [configPath] is the path to the JSON config that will be passed at start.
  ///
  /// Returns true on success.
  static Future<bool> install(String exePath, String configPath) async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: installing service');
    try {
      // sc create InputVPNService binpath= "C:\...\sing-box.exe run -c C:\...\config.json --disable-color" start= demand
      final binPath = '"$exePath" run -c "$configPath" --disable-color';
      final result = await _runElevated('sc', [
        'create', serviceName,
        'binpath=', binPath,
        'start=', 'demand',
        'DisplayName=', serviceDisplayName,
      ]);
      if (result) {
        AppLogger.info('ServiceManager: service installed successfully');
        // Grant the current user permission to start/stop without UAC.
        await _grantServicePermissions();
      } else {
        AppLogger.error('ServiceManager: installation failed');
      }
      return result;
    } catch (e) {
      AppLogger.error('ServiceManager.install error: $e');
      return false;
    }
  }

  /// Remove the Windows Service. Requires elevation — prompts UAC once.
  static Future<bool> remove() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: removing service');
    try {
      await stop(); // ensure stopped first
      final result = await _runElevated('sc', ['delete', serviceName]);
      if (result) {
        AppLogger.info('ServiceManager: service removed');
      } else {
        AppLogger.error('ServiceManager: removal failed');
      }
      return result;
    } catch (e) {
      AppLogger.error('ServiceManager.remove error: $e');
      return false;
    }
  }

  // ── Lifecycle (no elevation needed after install) ────────────────────────────

  /// Update the service config path and start it.
  ///
  /// [configPath] is written BEFORE calling this — the service binary
  /// already has the path baked in from [install], so we just start it.
  static Future<bool> start() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: starting service');
    try {
      final result = await Process.run('sc', ['start', serviceName]);
      final ok = result.exitCode == 0 ||
          (result.stderr as String).contains('already running');
      debugPrint(
        'sc start: exit=${result.exitCode} '
        'stdout=${result.stdout} stderr=${result.stderr}',
      );
      if (ok) {
        AppLogger.info('ServiceManager: service started');
      } else {
        AppLogger.error('ServiceManager: start failed — ${result.stderr}');
      }
      return ok;
    } catch (e) {
      AppLogger.error('ServiceManager.start error: $e');
      return false;
    }
  }

  /// Stop the running service without elevation.
  static Future<bool> stop() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: stopping service');
    try {
      final result = await Process.run('sc', ['stop', serviceName]);
      // Exit 1062 = service has not been started — treat as OK.
      final ok = result.exitCode == 0 ||
          (result.stdout as String).contains('1062');
      debugPrint(
        'sc stop: exit=${result.exitCode} '
        'stdout=${result.stdout} stderr=${result.stderr}',
      );
      if (ok) AppLogger.info('ServiceManager: service stopped');
      return ok;
    } catch (e) {
      AppLogger.error('ServiceManager.stop error: $e');
      return false;
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────────

  /// Returns true if the service is currently installed.
  static Future<bool> isInstalled() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run('sc', ['query', serviceName]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the service is in RUNNING state.
  static Future<bool> isRunning() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run('sc', ['query', serviceName]);
      return (result.stdout as String).contains('RUNNING');
    } catch (_) {
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Run [exe] with [args] via ShellExecuteEx runas (elevation).
  /// Returns true if the elevated process exited with code 0.
  static Future<bool> _runElevated(String exe, List<String> args) async {
    // We can't get the exit code of ShellExecuteEx directly.
    // Workaround: wrap in cmd /c and redirect exit code to a temp file.
    final argsStr = args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
    final tempFile =
        File('${Directory.systemTemp.path}\\inputvpn_sc_result.txt');

    // Build a cmd script that runs sc and writes errorlevel to a file.
    final script =
        '$exe $argsStr & echo %errorlevel% > "${tempFile.path}"';

    final result = await Process.run('powershell', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      'Start-Process cmd.exe -ArgumentList \'/c $script\' '
          '-Verb RunAs -Wait',
    ]);

    debugPrint('_runElevated result: exit=${result.exitCode}');

    // Read the exit code written by the script.
    try {
      if (await tempFile.exists()) {
        final text = (await tempFile.readAsString()).trim();
        await tempFile.delete();
        return text == '0';
      }

    } catch (_) {}

    // If we can't read the file, assume success if powershell itself exited 0.
    return result.exitCode == 0;
  }

  /// Grant the current user START and STOP permissions on the service
  /// without requiring full admin rights going forward.
  /// Uses sc sdset to modify the DACL.
  static Future<void> _grantServicePermissions() async {
    try {
      // Get the current user SID via whoami /user.
      final whoami = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        r'(New-Object System.Security.Principal.NTAccount($env:USERNAME))'r'.Translate([System.Security.Principal.SecurityIdentifier]).Value',
      ]);
      final sid = (whoami.stdout as String).trim();
      if (sid.isEmpty) { return; }

      // Build SDDL: grant sid RP WP (start/stop) on the service.
      // Full admin rights remain; we only add user rights.
      final sddl = 'D:(A;;RPWP;;;$sid)(A;;FA;;;SY)(A;;FA;;;BA)';
      await Process.run('sc', ['sdset', serviceName, sddl]);
      AppLogger.info('ServiceManager: permissions granted for SID $sid');
    } catch (e) {
      AppLogger.warn('ServiceManager: could not set permissions: $e');
    }
  }
}
