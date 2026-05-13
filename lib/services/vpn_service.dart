import 'dart:async';
import 'dart:math';

import 'package:vpn/models/parsed_config.dart';

/// Connection lifecycle status states.
sealed class ConnectionStatus {
  const ConnectionStatus();
  bool get isConnected => this is Connected;
  bool get isConnecting => this is Connecting;
  bool get isDisconnected => this is Disconnected;
}

class Disconnected extends ConnectionStatus {
  const Disconnected({this.failure});
  final ConnectionFailure? failure;
}

class Connecting extends ConnectionStatus {
  const Connecting();
}

class Connected extends ConnectionStatus {
  const Connected({required this.since});
  final DateTime since;
}

/// Typed connection failure errors.
sealed class ConnectionFailure {
  const ConnectionFailure(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class NoActiveConfig extends ConnectionFailure {
  const NoActiveConfig() : super('No active VPN configuration selected.');
}

class BackendNotImplemented extends ConnectionFailure {
  const BackendNotImplemented()
      : super(
          'Native VPN backend is not yet integrated. '
          'Connection is simulated for UI testing.',
        );
}

class UnexpectedFailure extends ConnectionFailure {
  const UnexpectedFailure(super.message);
}

/// Throughput sample exposed by the VPN backend.
class VpnStats {
  const VpnStats({
    required this.downloadBytesPerSec,
    required this.uploadBytesPerSec,
    required this.pingMs,
  });
  final double downloadBytesPerSec;
  final double uploadBytesPerSec;
  final int pingMs;

  static const empty = VpnStats(
    downloadBytesPerSec: 0,
    uploadBytesPerSec: 0,
    pingMs: 0,
  );

  String get downloadHuman => _humanize(downloadBytesPerSec);
  String get uploadHuman => _humanize(uploadBytesPerSec);

  static String _humanize(double bps) {
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

/// Backend-agnostic VPN service contract.
///
/// The real implementation wraps a native engine (sing-box).
/// [MockVpnService] emulates the lifecycle so the rest of the app stays decoupled.
abstract class VpnService {
  /// Latest known status.
  ConnectionStatus get status;

  /// Status stream. Emits the current status immediately on subscription.
  Stream<ConnectionStatus> watchStatus();

  /// Throughput stream while connected. Emits [VpnStats.empty] otherwise.
  Stream<VpnStats> watchStats();

  /// Establish a tunnel using [config]. Must be idempotent: calling while
  /// already connected/connecting is a no-op.
  Future<void> connect(ParsedConfig config);

  /// Tear down the tunnel.
  Future<void> disconnect();

  /// Restart the tunnel with a new config (disconnect + connect).
  Future<void> reconnect(ParsedConfig config);

  /// Release all resources. After [dispose] the instance is unusable.
  Future<void> dispose();
}

/// Mock backend used until the real native engine is wired up.
///
/// Behavior:
///   - `connect()` sets state to [Connecting] for ~1.5s, then [Connected].
///   - Emits fake stats while connected (ping based on link "quality",
///     throughput as a random walk).
///   - Never actually routes any traffic — DO NOT ship as production.
class MockVpnService implements VpnService {
  MockVpnService();

  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  final _statsCtrl = StreamController<VpnStats>.broadcast();
  ConnectionStatus _status = const Disconnected();
  Timer? _statsTimer;
  Timer? _connectTimer;
  final _rng = Random();

  @override
  ConnectionStatus get status => _status;

  @override
  Stream<ConnectionStatus> watchStatus() async* {
    yield _status;
    yield* _statusCtrl.stream;
  }

  @override
  Stream<VpnStats> watchStats() async* {
    yield VpnStats.empty;
    yield* _statsCtrl.stream;
  }

  void _setStatus(ConnectionStatus next) {
    _status = next;
    _statusCtrl.add(next);
  }

  @override
  Future<void> connect(ParsedConfig config) async {
    if (_status is Connected || _status is Connecting) return;
    _setStatus(const Connecting());
    _connectTimer?.cancel();
    final completer = Completer<void>();
    _connectTimer = Timer(const Duration(milliseconds: 1500), () {
      _setStatus(Connected(since: DateTime.now()));
      _startStats();
      completer.complete();
    });
    await completer.future;
  }

  @override
  Future<void> disconnect() async {
    _connectTimer?.cancel();
    _statsTimer?.cancel();
    _statsCtrl.add(VpnStats.empty);
    _setStatus(const Disconnected());
  }

  @override
  Future<void> reconnect(ParsedConfig config) async {
    await disconnect();
    await connect(config);
  }

  void _startStats() {
    _statsTimer?.cancel();
    double down = 1.5 * 1024 * 1024;
    double up = 200.0 * 1024;
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      down = (down + (_rng.nextDouble() - 0.5) * 200 * 1024)
          .clamp(50000.0, 25000000.0);
      up = (up + (_rng.nextDouble() - 0.5) * 40 * 1024)
          .clamp(10000.0, 5000000.0);
      _statsCtrl.add(VpnStats(
        downloadBytesPerSec: down,
        uploadBytesPerSec: up,
        pingMs: 35 + _rng.nextInt(50),
      ));
    });
  }

  @override
  Future<void> dispose() async {
    _connectTimer?.cancel();
    _statsTimer?.cancel();
    await _statusCtrl.close();
    await _statsCtrl.close();
  }
}
