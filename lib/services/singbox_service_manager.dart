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
      // sc.exe requires key=value as a single token (no space between = and value).
      final binPath = '"$exePath" run -c "$configPath" --disable-color';
      final result = await _runElevated('sc', [
        'create', serviceName,
        'binpath=$binPath',
        'start=demand',
        'DisplayName=$serviceDisplayName',
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

  /// Run [exe] with [args] elevated (UAC). Returns true iff the command
  /// exited with code 0.
  ///
  /// Strategy:
  ///  1. Write a temp `.ps1` that calls the command and saves `$LASTEXITCODE`
  ///     to a result file.
  ///  2. Run that PS1 via `Start-Process powershell -Verb RunAs -Wait`
  ///     (this is the UAC prompt).
  ///  3. Read the result file to get the real exit code.
  ///
  /// Why not use `cmd /c`?  PowerShell's `-ArgumentList '/c ...'` mangles
  /// complex quoting (double-quotes inside single-quotes break sc create).
  ///
  /// Why not check `Start-Process` own exit?  `Start-Process -Wait` always
  /// returns 0 from the outer PowerShell — it does NOT forward the child
  /// process exit code.  We must use the result file.
  static Future<bool> _runElevated(String exe, List<String> args) async {
    if (!Platform.isWindows) return false;

    // 'sc' is an alias for Set-Content in PowerShell; use the real binary.
    final exeName = (exe == 'sc') ? 'sc.exe' : exe;

    final tempDir = Directory.systemTemp.path;
    // Use simple fixed names — only one install/remove runs at a time.
    final ps1Path    = '$tempDir\\inputvpn_elev.ps1';
    final resultPath = '$tempDir\\inputvpn_elev_exit.txt';

    // Escape a value for a PS1 double-quoted string.
    // We wrap each argument in a double-quoted PS1 string literal so that
    // PowerShell passes it as a single token to sc.exe (preserving spaces
    // and embedded double-quotes, which we escape as `").
    String psArg(String s) {
      // Inside PS1 double-quoted strings: escape $ ` " with backtick.
      final escaped = s
          .replaceAll('`', '``')
          .replaceAll('"', '`"')
          .replaceAll(r'$', '`\$');
      return '"$escaped"';
    }

    // Build PS1: assign each argument to an array element, then splat.
    //   $a = @( 'sc.exe', 'create', 'InputVPNService', 'binpath=...', ... )
    //   & $a[0] $a[1..($a.Length-1)]
    final allArgs = [exeName, ...args];
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
    AppLogger.info('ServiceManager: PS1 content:\n$ps1Content');

    try {
      // Outer (non-elevated) PowerShell launches the PS1 elevated and waits.
      final outer = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        'Start-Process powershell.exe '
            "-ArgumentList @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',${psArg(ps1Path)}) "
            '-Verb RunAs -Wait',
      ]);

      debugPrint('_runElevated outer exit=${outer.exitCode} '
          'stderr=${outer.stderr}');

      final resultFile = File(resultPath);
      if (await resultFile.exists()) {
        final text = (await resultFile.readAsString()).trim();
        try { await resultFile.delete(); } catch (_) {}
        final code = int.tryParse(text) ?? 1;
        AppLogger.info('ServiceManager: elevated cmd exit=$code');
        return code == 0;
      }

      // Result file absent: UAC was denied or PS1 was blocked.
      AppLogger.warn('ServiceManager: elevated result file missing '
          '(UAC denied or script blocked)');
      return false;
    } catch (e) {
      AppLogger.error('ServiceManager: _runElevated error: $e');
      return false;
    } finally {
      try { await File(ps1Path).delete(); } catch (_) {}
    }
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
