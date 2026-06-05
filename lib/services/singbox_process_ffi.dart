import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:input_vpn/models/connection_failure.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/network_utils.dart';
import 'package:input_vpn/services/singbox_ffi.dart';

/// Manages the sing-box core via [SingboxFfi] (in-process DLL).
///
/// This replaces the old [SingBoxProcess] ShellExecuteEx approach:
/// - No separate elevated process — sing-box runs inside the DLL loaded by our app.
/// - No UAC per-connect — elevation is requested once at app startup via the
///   `requireAdministrator` manifest entry.
/// - Stop is a direct function call → adapter cleaned up synchronously.
///
/// For proxy (SOCKS) mode the DLL is still used — no TUN means no elevation
/// needed, but the same DLL interface is used for consistency.
class SingBoxProcessFfi {
  SingBoxProcessFfi();

  File? _logFile;
  bool _running = false;

  bool get isRunning => _running;
  File? get logFile => _logFile;

  // proxy/service mode flags kept for API compatibility with callers
  int get processId => 0;

  /// Resolve (and create) the work directory + log file path.
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

  /// Extract the last FATAL/ERROR line from the log tail.
  Future<String> extractFatalError({int maxLines = 50}) async {
    // First check if the FFI layer has an error
    final ffiErr = SingboxFfi.instance.lastError();
    if (ffiErr != null && ffiErr.isNotEmpty) return ffiErr;

    final tail = await tailLog(maxLines: maxLines);
    final match = RegExp(r'(?:FATAL|ERROR)\[[^\]]*\]\s*(.+?)(?:\n|$)')
        .allMatches(tail)
        .lastOrNull;
    if (match != null) return match.group(1)!.trim();
    final first =
        tail.split('\n').where((l) => l.trim().isNotEmpty).firstOrNull;
    return first ?? 'Unknown error (check sing-box.log)';
  }

  /// Start sing-box with the provided JSON config via the FFI DLL.
  ///
  /// [elevated] and [serviceMode] parameters are kept for API compatibility
  /// but are ignored — the DLL always runs in-process.
  Future<int> start(
    String configJson, {
    required bool elevated,
    bool serviceMode = false,
  }) async {
    if (_running) {
      throw const SingBoxStartException(
        'sing-box is already running. Call stop() first.',
      );
    }

    final ws = await prepareWorkDir();
    _logFile = File(ws.logPath);

    AppLogger.info('SingBoxProcessFfi: starting via FFI DLL');

    final ok = SingboxFfi.instance.start(configJson);
    if (!ok) {
      final err = SingboxFfi.instance.lastError() ?? 'unknown error';
      throw SingBoxStartException('sing-box DLL failed to start: $err');
    }

    _running = true;
    AppLogger.info('SingBoxProcessFfi: started');
    return 0;
  }

  /// Stop the running sing-box instance via the FFI DLL.
  Future<void> stop() async {
    AppLogger.info('SingBoxProcessFfi: stopping via FFI DLL');
    SingboxFfi.instance.stop();
    _running = false;
    debugPrint('SingBoxProcessFfi: stopped');

    AppLogger.info('SingBoxProcessFfi: cleaning up TUN adapter and DNS');
    await _cleanupWithRetry();
  }

  /// Retry network cleanup up to 3 times with delays.
  Future<void> _cleanupWithRetry() async {
    const maxRetries = 3;
    const delays = [Duration(milliseconds: 500), Duration(seconds: 1), Duration(seconds: 2)];

    for (int i = 0; i < maxRetries; i++) {
      try {
        await NetworkUtils.globalCleanup();
        AppLogger.info('SingBoxProcessFfi: cleanup succeeded on attempt ${i + 1}');
        return;
      } catch (e) {
        AppLogger.warn('SingBoxProcessFfi: cleanup attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          await Future<void>.delayed(delays[i]);
        }
      }
    }
    AppLogger.error('SingBoxProcessFfi: cleanup failed after $maxRetries attempts');
  }

  /// Returns true if sing-box is currently running.
  Future<bool> isProcessAlive() async {
    return SingboxFfi.instance.isRunning();
  }
}
