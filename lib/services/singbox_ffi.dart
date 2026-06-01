import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

// ── Native function signatures ────────────────────────────────────────────────

typedef _StartNative = Int32 Function(Pointer<Utf8> configJson);
typedef _StartDart = int Function(Pointer<Utf8> configJson);

typedef _StopNative = Void Function();
typedef _StopDart = void Function();

typedef _IsRunningNative = Int32 Function();
typedef _IsRunningDart = int Function();

typedef _LastErrorNative = Pointer<Utf8> Function();
typedef _LastErrorDart = Pointer<Utf8> Function();

// ── SingboxFfi ────────────────────────────────────────────────────────────────

/// Low-level FFI binding to `singbox_core.dll`.
///
/// Exposes [start], [stop], [isRunning] and [lastError].
/// The DLL must sit next to the runner `.exe` (copied there by CMake).
class SingboxFfi {
  SingboxFfi._();

  static SingboxFfi? _instance;

  static SingboxFfi get instance {
    _instance ??= SingboxFfi._().._load();
    return _instance!;
  }

  late final _StartDart _start;
  late final _StopDart _stop;
  late final _IsRunningDart _isRunning;
  late final _LastErrorDart _lastError;

  void _load() {
    final dllPath = _resolveDllPath();
    debugPrint('SingboxFfi: loading $dllPath');
    final lib = DynamicLibrary.open(dllPath);

    _start = lib
        .lookup<NativeFunction<_StartNative>>('SingboxStart')
        .asFunction<_StartDart>();

    _stop = lib
        .lookup<NativeFunction<_StopNative>>('SingboxStop')
        .asFunction<_StopDart>();

    _isRunning = lib
        .lookup<NativeFunction<_IsRunningNative>>('SingboxIsRunning')
        .asFunction<_IsRunningDart>();

    _lastError = lib
        .lookup<NativeFunction<_LastErrorNative>>('SingboxLastError')
        .asFunction<_LastErrorDart>();

    debugPrint('SingboxFfi: loaded successfully');
  }

  String _resolveDllPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return p.join(exeDir, 'singbox_core.dll');
  }

  /// Start sing-box with the provided JSON config.
  /// Returns true on success, false on error (check [lastError]).
  bool start(String configJson) {
    final ptr = configJson.toNativeUtf8();
    try {
      final result = _start(ptr);
      return result == 0;
    } finally {
      malloc.free(ptr);
    }
  }

  /// Stop the running sing-box instance. No-op if not running.
  void stop() => _stop();

  /// Returns true if sing-box is currently running.
  bool isRunning() => _isRunning() == 1;

  /// Returns the last error message, or null if no error.
  String? lastError() {
    final ptr = _lastError();
    if (ptr == nullptr) return null;
    return ptr.toDartString();
  }
}
