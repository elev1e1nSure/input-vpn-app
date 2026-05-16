import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Application-level event logger.
///
/// Writes timestamped lines to `app.log` in the same directory as
/// `sing-box.log` (`%APPDATA%\InputVPN\singbox\`). Persists across sessions.
///
/// Usage:
///   await AppLogger.init();
///   AppLogger.info('VPN connected');
///   AppLogger.error('Connection failed: $e');
class AppLogger {
  AppLogger._();

  static File? _logFile;
  static IOSink? _sink;
  static bool _ready = false;

  static const int _maxBytes = 1024 * 1024; // 1 MB rotation threshold
  static const int _keepLines = 500;

  /// Must be called once before using [info] / [error].
  static Future<void> init() async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'singbox'));
      if (!dir.existsSync()) dir.createSync(recursive: true);

      _logFile = File(p.join(dir.path, 'app.log'));

      // Rotate if oversized.
      if (_logFile!.existsSync() && _logFile!.lengthSync() > _maxBytes) {
        await _rotate(_logFile!);
      }

      _sink = _logFile!.openWrite(mode: FileMode.append);
      _ready = true;
      info('AppLogger initialised — log: ${_logFile!.path}');
    } catch (e) {
      debugPrint('AppLogger.init failed: $e');
    }
  }

  /// Returns the [File] handle, or null if not initialised yet.
  static File? get logFile => _logFile;

  static void info(String message) => _write('INFO ', message);
  static void error(String message) => _write('ERROR', message);
  static void warn(String message) => _write('WARN ', message);

  static void _write(String level, String message) {
    if (!_ready) {
      debugPrint('[$level] $message');
      return;
    }
    final now = DateTime.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} '
        '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
    final line = '[$ts] $level $message\n';
    try {
      _sink?.write(line);
    } catch (e) {
      debugPrint('AppLogger write error: $e');
    }
    debugPrint(line.trimRight());
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Trim the file to the last [_keepLines] lines.
  static Future<void> _rotate(File file) async {
    try {
      final lines = await file.readAsLines();
      final kept = lines.length > _keepLines
          ? lines.sublist(lines.length - _keepLines)
          : lines;
      await file.writeAsString('${kept.join('\n')}\n');
    } catch (e) {
      debugPrint('AppLogger rotate error: $e');
    }
  }

  /// Read the current log file contents. Returns empty string if not ready.
  static Future<String> readAll() async {
    final f = _logFile;
    if (f == null || !f.existsSync()) return '';
    try {
      return await f.readAsString();
    } catch (e) {
      return '<read error: $e>';
    }
  }

  /// Clear only app.log (does not touch sing-box.log).
  static Future<void> clear() async {
    try {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;
      final f = _logFile;
      if (f != null && f.existsSync()) {
        await f.writeAsString('');
      }
      _sink = _logFile?.openWrite(mode: FileMode.append);
      info('Log cleared');
    } catch (e) {
      debugPrint('AppLogger.clear error: $e');
    }
  }

  /// Flush and close the sink (call on app exit if needed).
  static Future<void> dispose() async {
    try {
      await _sink?.flush();
      await _sink?.close();
      _sink = null;
      _ready = false;
    } catch (_) {}
  }
}
