import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/models/connection_failure.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/vpn/windows/network_utils.dart';
import 'package:input_vpn/services/vpn/windows/singbox_service_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Spawns and manages a `sing-box.exe` child process.
///
/// The app runs with `requireAdministrator` in its manifest, so every child
/// process launched via [Process.start] inherits the elevated token — no UAC
/// prompt on every connect.
class SingBoxProcess {
  SingBoxProcess();

  int _processId = 0;
  File? _logFile;
  bool _serviceMode = false;
  bool _serviceModeRunning = false;

  bool get isRunning => _serviceMode
      ? _serviceModeRunning
      : _normalProc != null && !_normalProcExited;
  int get processId => _processId;
  File? get logFile => _logFile;

  Future<({Directory dir, String logPath, String configPath})>
      prepareWorkDir() async {
    final dir = await _workDir();
    return (
      dir: dir,
      logPath: p.join(dir.path, 'sing-box.log'),
      configPath: p.join(dir.path, 'config.json'),
    );
  }

  Future<Directory> _workDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'singbox'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

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
    } on Exception catch (e) {
      return '<failed to read log: $e>';
    }
  }

  Future<String> extractFatalError({int maxLines = 50}) async {
    final tail = await tailLog(maxLines: maxLines);
    final match = RegExp(r'(?:FATAL|ERROR)\[[^\]]*\]\s*(.+?)(?:\n|$)')
        .allMatches(tail)
        .lastOrNull;
    if (match != null) return match.group(1)!.trim();
    final first =
        tail.split('\n').where((l) => l.trim().isNotEmpty).firstOrNull;
    return first ?? 'Unknown error (check sing-box.log)';
  }

  String _singBoxPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return p.join(exeDir, 'sing-box.exe');
  }

  Process? _normalProc;
  bool _normalProcExited = false;

  Future<int> start(
    String configJson, {
    required bool elevated,
    bool serviceMode = false,
  }) async {
    // Clean up stale reference from a previous unexpected exit.
    if (_normalProcExited && _normalProc != null) {
      _normalProc = null;
      _normalProcExited = false;
    }

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
    await _logFile!.writeAsString('', flush: true);

    // ── Service mode ───────────────────────────────────────────────────────
    if (serviceMode) {
      AppLogger.info('SingBoxProcess: starting via Windows Service');
      final installed = await SingboxServiceManager.isInstalled();
      if (installed) {
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
      AppLogger.warn(
          'SingBoxProcess: service not installed — falling back to direct launch');
      // Fall through to direct launch below.
    }

    _serviceMode = false;

    // Pre-flight TUN cleanup to avoid stale adapter on reconnect.
    if (elevated) {
      await NetworkUtils.globalCleanup();
    }

    // Launch sing-box directly. The app is elevated via requireAdministrator
    // manifest, so the child inherits the elevated token without a UAC prompt.
    AppLogger.info('SingBoxProcess: launching sing-box.exe');
    final proc = await Process.start(
      exe,
      ['run', '-c', configFile.path, '--disable-color'],
      workingDirectory: ws.dir.path,
    );

    final logSink = _logFile!.openWrite(mode: FileMode.append);
    proc.stdout.listen(logSink.add, onError: (_) {}, cancelOnError: false);
    proc.stderr.listen(logSink.add, onError: (_) {}, cancelOnError: false);
    _normalProc = proc;
    _normalProcExited = false;
    _processId = proc.pid;

    unawaited(proc.exitCode.then((_) {
      _normalProcExited = true;
      try {
        logSink.close();
      } on Exception catch (_) {}
    }));

    AppLogger.info('SingBoxProcess: started (pid=$_processId)');
    return proc.pid;
  }

  Future<void> stop() async {
    // ── Service mode ───────────────────────────────────────────────────────
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
    debugPrint('SingBoxProcess: stopping process (pid=$_processId)...');

    if (proc != null) {
      try {
        proc.kill();
        await proc.exitCode.timeout(const Duration(seconds: 3));
      } on Exception catch (_) {
        try {
          proc.kill(ProcessSignal.sigkill);
        } on Exception catch (_) {}
      }
      _normalProc = null;
    }

    // Safety net: ensure no stray sing-box process remains.
    if (await _isSingBoxRunningByName()) {
      try {
        await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F', '/T']);
      } on Exception catch (_) {}
    }

    _processId = 0;

    // Give sing-box time to fully release the TUN adapter before removing it.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await NetworkUtils.globalCleanup();
    debugPrint('SingBoxProcess: stop and cleanup finished.');
  }

  Future<bool> isProcessAlive() async {
    if (_serviceMode) return _serviceModeRunning;
    final proc = _normalProc;
    if (proc != null) return !_normalProcExited;
    return await _isSingBoxRunningByName();
  }

  Future<bool> _isSingBoxRunningByName() async {
    try {
      final r = await Process.run('tasklist',
          ['/FI', 'IMAGENAME eq sing-box.exe', '/FO', 'CSV', '/NH']);
      return r.stdout.toString().toLowerCase().contains('sing-box.exe');
    } on Exception catch (_) {
      return false;
    }
  }
}
