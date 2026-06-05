import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/services/app_logger.dart';

/// Manages sing-box via a Windows Scheduled Task running as SYSTEM.
///
/// Why Scheduled Task instead of a Windows Service?
/// sing-box.exe is not a proper SCM service — it does not call
/// SetServiceStatus(), so `sc start` always times out after 30 s.
/// A scheduled task with `/ru SYSTEM` starts sing-box instantly as
/// SYSTEM (which can create TUN adapters) without any UAC prompt after
/// the one-time task registration.
///
/// The task is created by the Inno Setup installer (admin rights) during
/// setup. The Flutter runtime only starts, stops, and queries the task.
///
/// Lifecycle:
///   start(path) — schtasks /run  (no elevation, works for any user).
///   stop()      — taskkill sing-box.exe (no elevation).
///   isInstalled() — schtasks /query.
class SingboxServiceManager {
  static const String serviceName = 'InputVPNService';
  static const String _taskName = 'InputVPNSingBox';

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  /// Update the config path in the task and run it as SYSTEM immediately.
  /// No elevation required after install().
  static Future<bool> start(String exePath, String configPath) async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: updating task config and starting');
    try {
      // Update the task command to point to the current config file.
      final changeArgs = [
        '/change',
        '/tn',
        _taskName,
        '/tr',
        '"$exePath" run -c "$configPath" --disable-color',
      ];
      final change = await Process.run('schtasks.exe', changeArgs);
      debugPrint('schtasks change: exit=${change.exitCode} '
          'stdout=${change.stdout} stderr=${change.stderr}');

      // Run the task immediately.
      final run = await Process.run('schtasks.exe', ['/run', '/tn', _taskName]);
      debugPrint('schtasks run: exit=${run.exitCode} '
          'stdout=${run.stdout} stderr=${run.stderr}');
      final ok = run.exitCode == 0;
      if (ok) {
        AppLogger.info('ServiceManager: task started');
      } else {
        AppLogger.error('ServiceManager: start failed — ${run.stderr}');
      }
      return ok;
    } catch (e) {
      AppLogger.error('ServiceManager.start error: $e');
      return false;
    }
  }

  /// Kill sing-box.exe via the SYSTEM-level [InputVPNStop] scheduled task.
  ///
  /// Running a task as SYSTEM allows it to terminate privileged (elevated /
  /// SYSTEM) sing-box processes that a medium-IL Flutter process cannot kill
  /// with a plain `taskkill`. No UAC prompt is shown.
  ///
  /// Returns true when sing-box.exe is confirmed gone (or was already gone).
  /// Returns false if the task is not installed or the process did not stop
  /// within the polling window — callers should fall back to a direct taskkill.
  static Future<bool> stopViaSchtask() async {
    if (!Platform.isWindows) return false;

    const stopTask = 'InputVPNStop';

    // Trigger the stop task directly. If the task is not installed, /run
    // returns a non-zero exit code — treat that as "not available" and let
    // callers fall back to direct taskkill. Skipping a /query pre-check avoids
    // locale/OEM-encoding issues with schtasks.exe output on non-English Windows.
    AppLogger.info('ServiceManager: triggering $stopTask task');
    try {
      final run = await Process.run('schtasks.exe', ['/run', '/tn', stopTask]);
      debugPrint(
          'schtasks /run $stopTask: exit=${run.exitCode} stdout=${run.stdout} stderr=${run.stderr}');
      if (run.exitCode != 0) {
        AppLogger.warn(
            'ServiceManager: $stopTask /run failed (exit=${run.exitCode}) — task not installed?');
        return false;
      }
    } catch (e) {
      AppLogger.error('ServiceManager: failed to run $stopTask: $e');
      return false;
    }

    // Poll until sing-box.exe disappears (max ~5 s).
    for (int i = 0; i < 25; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!await isRunning()) {
        AppLogger.info('ServiceManager: sing-box stopped via $stopTask');
        return true;
      }
    }

    AppLogger.warn(
        'ServiceManager: sing-box still running after $stopTask — timed out');
    return false;
  }

  /// Kill sing-box.exe. Tries the SYSTEM-level [InputVPNStop] scheduled task
  /// first; falls back to a direct taskkill if the task is missing.
  static Future<bool> stop() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: stopping sing-box');

    if (await stopViaSchtask()) return true;

    // Fallback: direct taskkill (works when the app itself is elevated or
    // the stop task is not installed on older setups).
    AppLogger.info(
        'ServiceManager: fallback — direct taskkill /IM sing-box.exe /F');
    try {
      final result =
          await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F']);
      final ok = result.exitCode == 0 ||
          (result.stdout as String).contains('not found') ||
          (result.stderr as String).contains('not found');
      if (ok)
        AppLogger.info(
            'ServiceManager: sing-box stopped via taskkill fallback');
      return true; // treat "not running" as success
    } catch (e) {
      AppLogger.error('ServiceManager.stop error: $e');
      return false;
    }
  }

  // ── Status ───────────────────────────────────────────────────────────────────

  /// Returns true if the scheduled task is registered.
  static Future<bool> isInstalled() async {
    if (!Platform.isWindows) return false;
    try {
      final result =
          await Process.run('schtasks.exe', ['/query', '/tn', _taskName]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if sing-box.exe is currently running.
  static Future<bool> isRunning() async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run(
          'tasklist', ['/FI', 'IMAGENAME eq sing-box.exe', '/NH']);
      return (result.stdout as String).contains('sing-box.exe');
    } catch (_) {
      return false;
    }
  }
}
