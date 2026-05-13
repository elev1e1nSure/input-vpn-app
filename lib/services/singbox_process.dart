import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:win32/win32.dart';

/// Spawns and manages a `sing-box.exe` child process with admin (UAC)
/// elevation, needed for the TUN device to function on Windows.
///
/// Layout (after `flutter build windows`):
///   <runner.exe>
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

  bool get isRunning => _processHandle != 0;
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

  /// Find the bundled sing-box.exe next to our own runner exe.
  String _singBoxPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return p.join(exeDir, 'sing-box.exe');
  }

  /// Start sing-box with the provided JSON config.
  ///
  /// Returns the OS process id. Throws [SingBoxStartException] on failure.
  Future<int> start(String configJson) async {
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

    final pid = _shellExecuteElevated(
      exe: exe,
      args: ['run', '-c', configFile.path, '--disable-color'],
      workingDir: ws.dir.path,
    );
    _processId = pid;
    return pid;
  }

  /// Gracefully stop the elevated child process.
  Future<void> stop() async {
    if (_processHandle != 0) {
      // Try graceful shutdown via taskkill first (less likely to crash
      // the TUN driver).
      try {
        await Process.run('taskkill', ['/PID', '$_processId', '/T', '/F']);
      } catch (_) {}
      // Then close our handle.
      CloseHandle(_processHandle);
      _processHandle = 0;
      _processId = 0;
    }
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
    final exeUtf16 = exe.toNativeUtf16();
    final verbUtf16 = 'runas'.toNativeUtf16();
    // Quote arguments that contain spaces.
    final argString = args
        .map((a) => a.contains(' ') ? '"$a"' : a)
        .join(' ');
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
  bool isProcessAlive() {
    if (_processHandle == 0) return false;
    final exitCode = calloc<DWORD>();
    try {
      final ok = GetExitCodeProcess(_processHandle, exitCode);
      if (ok == 0) return false;
      // STILL_ACTIVE = 259
      return exitCode.value == 259;
    } finally {
      calloc.free(exitCode);
    }
  }
}

class SingBoxStartException implements Exception {
  const SingBoxStartException(this.message);
  final String message;
  @override
  String toString() => 'SingBoxStartException: $message';
}
