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
/// Lifecycle:
///   install()   — registers the task (one UAC / admin prompt).
///   start(path) — schtasks /run  (no elevation, works for any user).
///   stop()      — taskkill sing-box.exe (no elevation).
///   remove()    — schtasks /delete (one UAC / admin prompt).
///   isInstalled() — schtasks /query.
class SingboxServiceManager {
  static const String serviceName  = 'InputVPNService';
  static const String _taskName    = 'InputVPNSingBox';

  // ── Installation ────────────────────────────────────────────────────────────

  /// Register a Scheduled Task that runs sing-box as SYSTEM.
  /// Requires admin rights — prompts UAC once (or silently if already admin).
  /// [exePath] — absolute path to sing-box.exe.
  static Future<bool> install(String exePath, String configPath) async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: installing scheduled task');
    try {
      // schtasks /create registers an on-demand task running as SYSTEM.
      // /f overwrites any pre-existing task with the same name.
      // We use a dummy trigger (ONCE at a past time) so it never auto-starts.
      final args = [
        '/create', '/f',
        '/tn', _taskName,
        '/ru', 'SYSTEM',
        '/sc', 'ONCE',
        '/st', '00:00',
        '/sd', '01/01/2000',
        '/tr', '"$exePath" run -c "$configPath" --disable-color',
      ];

      // Try directly first (works when app is already elevated).
      final direct = await Process.run('schtasks.exe', args);
      debugPrint('schtasks create direct: exit=${direct.exitCode} '
          'stdout=${direct.stdout} stderr=${direct.stderr}');

      if (direct.exitCode == 0) {
        AppLogger.info('ServiceManager: task installed successfully');
        return true;
      }

      // Not admin — run elevated via PowerShell Start-Process.
      final ok = await _runElevated('schtasks.exe', args);
      if (ok) {
        AppLogger.info('ServiceManager: task installed successfully (elevated)');
      } else {
        AppLogger.error('ServiceManager: task installation failed');
      }
      return ok;
    } catch (e) {
      AppLogger.error('ServiceManager.install error: $e');
      return false;
    }
  }

  /// Delete the scheduled task. Requires admin.
  static Future<bool> remove() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: removing scheduled task');
    try {
      await stop();
      final direct = await Process.run('schtasks.exe',
          ['/delete', '/f', '/tn', _taskName]);
      if (direct.exitCode == 0) {
        AppLogger.info('ServiceManager: task removed');
        return true;
      }
      final ok = await _runElevated('schtasks.exe',
          ['/delete', '/f', '/tn', _taskName]);
      if (ok) AppLogger.info('ServiceManager: task removed (elevated)');
      return ok;
    } catch (e) {
      AppLogger.error('ServiceManager.remove error: $e');
      return false;
    }
  }

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
        '/tn', _taskName,
        '/tr', '"$exePath" run -c "$configPath" --disable-color',
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

  /// Kill sing-box.exe (task runs as SYSTEM so taskkill needs no elevation
  /// from an admin process; from a normal process it may need /F only).
  static Future<bool> stop() async {
    if (!Platform.isWindows) return false;
    AppLogger.info('ServiceManager: stopping sing-box');
    try {
      final result = await Process.run(
          'taskkill', ['/IM', 'sing-box.exe', '/F']);
      final ok = result.exitCode == 0 ||
          (result.stdout as String).contains('not found') ||
          (result.stderr as String).contains('not found');
      if (ok) AppLogger.info('ServiceManager: sing-box stopped');
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
      final result = await Process.run(
          'schtasks.exe', ['/query', '/tn', _taskName]);
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Run [exe] with [args] in an elevated process (UAC prompt).
  /// Returns true iff the child exited with code 0.
  static Future<bool> _runElevated(String exe, List<String> args) async {
    if (!Platform.isWindows) return false;

    final tempDir     = Directory.systemTemp.path;
    final ps1Path     = '$tempDir\\inputvpn_elev.ps1';
    final resultPath  = '$tempDir\\inputvpn_elev_exit.txt';

    String psArg(String s) {
      final escaped = s
          .replaceAll('`', '``')
          .replaceAll('"', '`"')
          .replaceAll(r'$', r'`$');
      return '"$escaped"';
    }

    final allArgs    = [exe, ...args];
    final arrayItems = allArgs.map(psArg).join(',\n  ');

    final ps1Content = '''
\$a = @(
  $arrayItems
)
\$out = & \$a[0] \$a[1..(\$a.Length-1)] 2>&1
\$code = \$LASTEXITCODE
Write-Host \$out
[System.IO.File]::WriteAllText(${psArg(resultPath)}, \$code.ToString())
exit \$code
''';

    await File(ps1Path).writeAsString(ps1Content, flush: true);

    try {
      final outer = await Process.run('powershell', [
        '-NoProfile', '-NonInteractive', '-Command',
        'Start-Process powershell.exe '
            "-ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',${psArg(ps1Path)}) "
            '-Verb RunAs -Wait',
      ]);
      debugPrint('_runElevated outer exit=${outer.exitCode}');

      final resultFile = File(resultPath);
      if (await resultFile.exists()) {
        final text = (await resultFile.readAsString()).trim();
        try { await resultFile.delete(); } catch (_) {}
        final code = int.tryParse(text) ?? 1;
        AppLogger.info('ServiceManager: elevated cmd exit=$code');
        return code == 0;
      }
      AppLogger.warn('ServiceManager: result file missing (UAC denied?)');
      return false;
    } catch (e) {
      AppLogger.error('ServiceManager: _runElevated error: $e');
      return false;
    } finally {
      try { await File(ps1Path).delete(); } catch (_) {}
    }
  }

}
