import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:input_vpn/models/connection_failure.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/vpn/windows/network_utils.dart';
import 'package:input_vpn/services/vpn/windows/singbox_service_manager.dart';
import 'package:win32/win32.dart';

/// Spawns and manages a `sing-box.exe` child process with admin (UAC)
/// elevation, needed for the TUN device to function on Windows.
///
/// Layout (after `flutter build windows`):
///   [runner.exe]
///   sing-box.exe       <- bundled by CMake post-build
///   wintun.dll         <- bundled by CMake post-build
///
/// Workflow:
///   1. [start] writes the config JSON to `%APPDATA%/InputVPN/config.json`,
///      then launches `sing-box.exe run -c config.json` via ShellExecuteEx
///      with verb=`runas`, which triggers the UAC prompt.
///   2. The child process keeps running until [stop] is called (Windows
///      `TerminateProcess`) or the user disconnects via the Clash API.
class SingBoxProcess {
  SingBoxProcess();

  /// Handle to the elevated child process. Null when not running.
  int _processHandle = 0;
  int _processId = 0;
  File? _logFile;

  /// Whether the last [start] used service mode.
  bool _serviceMode = false;

  bool get isRunning =>
      _serviceMode ? _serviceModeRunning : _processHandle != 0;
  bool _serviceModeRunning = false;
  int get processId => _processId;
  File? get logFile => _logFile;

  /// Resolve (and create) the work directory + log file path.
  /// Call this BEFORE [start] so the caller can wire `log.output` into the
  /// sing-box config.
  Future<({Directory dir, String logPath, String configPath})>
      prepareWorkDir() async {
    final dir = await _workDir();
    return (
      dir: dir,
      logPath: p.join(dir.path, 'sing-box.log'),
      configPath: p.join(dir.path, 'config.json'),
    );
  }

  /// Where we write logs/config.
  Future<Directory> _workDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'singbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Best-effort read of the most recent log lines for use in error messages.
  Future<String> tailLog({int maxLines = 30}) async {
    final f = _logFile;
    if (f == null || !await f.exists()) return '<no log file>';
    try {
      final text = await f.readAsString();
      final lines = text.split(RegExp(r'\r?\n'));
      final tail = lines.length <= maxLines
          ? lines
          : lines.sublist(lines.length - maxLines);
      return tail.join('\n').trim();
    } catch (e) {
      return '<failed to read log: $e>';
    }
  }

  /// Extract the last `FATAL[...]` or `ERROR[...]` line from the log tail.
  /// Returns the concise message suitable for UI display.
  Future<String> extractFatalError({int maxLines = 50}) async {
    final tail = await tailLog(maxLines: maxLines);
    // sing-box 1.13 prefixes fatals as: FATAL[0000] start service: ...
    final match = RegExp(r'(?:FATAL|ERROR)\[[^\]]*\]\s*(.+?)(?:\n|$)')
        .allMatches(tail)
        .lastOrNull;
    if (match != null) return match.group(1)!.trim();
    // Fallback: first non-empty line
    final first =
        tail.split('\n').where((l) => l.trim().isNotEmpty).firstOrNull;
    return first ?? 'Unknown error (check sing-box.log)';
  }

  /// Find the bundled sing-box.exe next to our own runner exe.
  String _singBoxPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return p.join(exeDir, 'sing-box.exe');
  }

  /// Reference to a non-elevated child Process so we can kill/await it.
  /// Null when we launched via ShellExecuteEx instead.
  Process? _normalProc;

  /// Start sing-box with the provided JSON config.
  ///
  /// When [serviceMode] is true, delegates to [SingboxServiceManager] which
  /// requires no UAC after the service has been installed. Falls back to the
  /// legacy elevated launch when false.
  ///
  /// When [elevated] is true (and serviceMode is false), uses [ShellExecuteEx]
  /// with the `runas` verb (UAC prompt). Required for TUN mode. Set to false
  /// for SOCKS-only mode to skip UAC.
  ///
  /// Returns the OS process id (0 for service mode). Throws [SingBoxStartException] on failure.
  Future<int> start(
    String configJson, {
    required bool elevated,
    bool serviceMode = false,
  }) async {
    if (isRunning) {
      throw const SingBoxStartException(
        'sing-box is already running. Call stop() first.',
      );
    }

    final exe = _singBoxPath();
    if (!File(exe).existsSync()) {
      throw SingBoxStartException(
        'sing-box.exe not found next to runner: $exe\n'
        'Place sing-box.exe in windows/runner/resources/ and rebuild.',
      );
    }

    final ws = await prepareWorkDir();
    final configFile = File(ws.configPath);
    await configFile.writeAsString(configJson, flush: true);
    _logFile = File(ws.logPath);
    // Truncate previous log.
    await _logFile!.writeAsString('', flush: true);

    // ── Service mode ──────────────────────────────────────────────────────────
    if (serviceMode) {
      AppLogger.info('SingBoxProcess: starting via Windows Service');
      final installed = await SingboxServiceManager.isInstalled();
      if (!installed) {
        // Service was never installed (UAC denied or removed externally).
        // Fall back to legacy elevated launch so the user isn't stuck.
        AppLogger.warn(
            'SingBoxProcess: service not installed — falling back to elevated launch');
      } else {
        // start() updates the task's command to the current config path
        // and runs it as SYSTEM instantly via schtasks /run.
        await NetworkUtils.globalCleanup();
        final ok = await SingboxServiceManager.start(exe, configFile.path);
        if (!ok) {
          throw const SingBoxStartException('Windows Service failed to start.');
        }
        _serviceMode = true;
        _serviceModeRunning = true;
        _processId = 0;
        return 0;
      }
      // Service not installed: fall through to legacy elevated mode below.
    }

    // ── Legacy elevated / non-elevated mode ───────────────────────────────────
    _serviceMode = false;

    // Pre-flight cleanup: remove old TUN and reset DNS if stuck.
    if (elevated) {
      await NetworkUtils.globalCleanup();
    }

    if (elevated) {
      final pid = _shellExecuteElevated(
        exe: exe,
        args: ['run', '-c', configFile.path, '--disable-color'],
        workingDir: ws.dir.path,
      );
      _processId = pid;
      return pid;
    }

    // Non-elevated launch: gives us a proper Process handle, stdout/stderr,
    // and exitCode access. Default `normal` mode is what we want.
    final proc = await Process.start(
      exe,
      ['run', '-c', configFile.path, '--disable-color'],
      workingDirectory: ws.dir.path,
    );
    // Tee stdout/stderr into the log file (sing-box also writes via log.output,
    // but this captures early panics that happen before the logger is built).
    final logSink = _logFile!.openWrite(mode: FileMode.append);
    proc.stdout.listen(logSink.add, onError: (_) {}, cancelOnError: false);
    proc.stderr.listen(logSink.add, onError: (_) {}, cancelOnError: false);
    _normalProc = proc;
    _normalProcExited = false;
    _processId = proc.pid;
    // Watch for unexpected exits.
    unawaited(proc.exitCode.then((_) {
      _normalProcExited = true;
      try {
        logSink.close();
      } catch (_) {}
    }));
    return proc.pid;
  }

  /// Gracefully stop the running sing-box process.
  Future<void> stop() async {
    // ── Service mode: delegate to sc stop ─────────────────────────────────────
    if (_serviceMode) {
      AppLogger.info('SingBoxProcess: stopping via Windows Service');
      await SingboxServiceManager.stop();
      _serviceModeRunning = false;
      _serviceMode = false;
      await NetworkUtils.globalCleanup();
      debugPrint('SingBoxProcess: service stopped and cleaned up.');
      return;
    }

    final proc = _normalProc;
    final pid = _processId;

    debugPrint('SingBoxProcess: stopping process (pid=$pid)...');

    if (proc != null) {
      // Non-elevated: standard kill
      try {
        proc.kill();
        await proc.exitCode.timeout(const Duration(seconds: 3));
      } catch (_) {
        try {
          proc.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
      _normalProc = null;
    } else if (pid != 0) {
      // Elevated: the Flutter process cannot kill a higher-IL process directly.
      // Use the SYSTEM-level InputVPNStop scheduled task which has SeDebugPrivilege.
      final stoppedViaSchtask = await SingboxServiceManager.stopViaSchtask();

      if (!stoppedViaSchtask) {
        // Fallback: direct taskkill (works if app is elevated or stop task missing)
        try {
          await Process.run('taskkill', ['/PID', '$pid', '/T']);

          int retry = 0;
          while (retry < 5 && await isProcessAlive()) {
            await Future<void>.delayed(const Duration(milliseconds: 200));
            retry++;
          }

          if (await isProcessAlive()) {
            await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
          }
        } catch (e) {
          debugPrint('SingBoxProcess: taskkill error: $e');
        }
      }
    }

    // Double check by name as a safety net
    if (await _isSingBoxRunningByName()) {
      try {
        await SingboxServiceManager.stopViaSchtask();
      } catch (_) {}
      if (await _isSingBoxRunningByName()) {
        try {
          await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F', '/T']);
        } catch (_) {}
      }
    }

    if (_processHandle != 0) {
      CloseHandle(_processHandle);
      _processHandle = 0;
    }
    _processId = 0;

    // Final cleanup as a safety net in case sing-box didn't clean up
    await NetworkUtils.globalCleanup();
    debugPrint('SingBoxProcess: stop and cleanup finished.');
  }

  /// Launches [exe] with [args] elevated. Returns the new process id.
  ///
  /// Uses [ShellExecuteEx] with verb `runas` (the standard way to request UAC
  /// elevation from a non-elevated parent). Output goes to [_logFile] via
  /// shell redirection — sing-box prints to stdout, but ShellExecute does NOT
  /// inherit pipes, so we rely on file logging instead and have sing-box
  /// write JSON status to its log file.
  int _shellExecuteElevated({
    required String exe,
    required List<String> args,
    required String workingDir,
  }) {
    final shellInfo = calloc<SHELLEXECUTEINFO>();
    // Quote the executable path itself if it contains spaces.
    final quotedExe = exe.contains(' ') ? '"$exe"' : exe;
    final exeUtf16 = quotedExe.toNativeUtf16();
    final verbUtf16 = 'runas'.toNativeUtf16();
    // Quote arguments that contain spaces.
    final argString = args.map((a) => a.contains(' ') ? '"$a"' : a).join(' ');
    final argsUtf16 = argString.toNativeUtf16();
    final workDirUtf16 = workingDir.toNativeUtf16();

    try {
      shellInfo.ref.cbSize = sizeOf<SHELLEXECUTEINFO>();
      // SEE_MASK_NOCLOSEPROCESS = 0x40, SEE_MASK_FLAG_NO_UI = 0x400.
      shellInfo.ref.fMask = 0x40;
      shellInfo.ref.lpVerb = verbUtf16;
      shellInfo.ref.lpFile = exeUtf16;
      shellInfo.ref.lpParameters = argsUtf16;
      shellInfo.ref.lpDirectory = workDirUtf16;
      // SW_HIDE = 0 (don't show a console window for the child).
      shellInfo.ref.nShow = 0;

      final ok = ShellExecuteEx(shellInfo);
      if (ok == 0) {
        final err = GetLastError();
        // 1223 = ERROR_CANCELLED — user clicked No on UAC prompt.
        if (err == 1223) {
          throw const SingBoxStartException(
            'Elevation was cancelled by the user.',
          );
        }
        throw SingBoxStartException(
          'ShellExecuteEx failed (GetLastError=$err) while launching $exe.',
        );
      }

      final hProc = shellInfo.ref.hProcess;
      if (hProc == 0) {
        throw const SingBoxStartException(
          'ShellExecuteEx returned a null process handle.',
        );
      }
      final pid = GetProcessId(hProc);
      _processHandle = hProc;

      // Give the elevated child a moment to own its handles before callers
      // poll isProcessAlive() or extractFatalError().
      sleep(const Duration(milliseconds: 600));

      return pid;
    } finally {
      calloc.free(exeUtf16);
      calloc.free(verbUtf16);
      calloc.free(argsUtf16);
      calloc.free(workDirUtf16);
      calloc.free(shellInfo);
    }
  }

  /// Returns true if the child process is still alive.
  ///
  /// For non-elevated launches this is reliable via the Dart Process API.
  /// For elevated launches via [ShellExecuteEx] our recorded handle is
  /// typically the (already-dead) UAC consent intermediate, so as a fallback
  /// we also scan running `sing-box.exe` instances by name.
  Future<bool> isProcessAlive() async {
    final proc = _normalProc;
    if (proc != null) {
      // Process.kill(signal: 0) is a portable "still alive" probe but Dart's
      // Process doesn't expose it. Track via cached exitCode future instead.
      // Until proc.exitCode completes, we treat it as alive.
      return !_normalProcExited;
    }
    if (_processHandle != 0) {
      final exitCode = calloc<DWORD>();
      try {
        final ok = GetExitCodeProcess(_processHandle, exitCode);
        // STILL_ACTIVE = 259
        if (ok != 0 && exitCode.value == 259) return true;
      } finally {
        calloc.free(exitCode);
      }
    }
    // Fallback: was launched elevated and the recorded handle is dead. Check
    // by image name. This is best-effort and may yield false positives if
    // another sing-box.exe is unrelated to us, but in our app that's fine.
    return await _isSingBoxRunningByName();
  }

  bool _normalProcExited = false;

  Future<bool> _isSingBoxRunningByName() async {
    try {
      final r = await Process.run('tasklist',
          ['/FI', 'IMAGENAME eq sing-box.exe', '/FO', 'CSV', '/NH']);
      final out = r.stdout.toString();
      return out.toLowerCase().contains('sing-box.exe');
    } catch (_) {
      return false;
    }
  }
}
