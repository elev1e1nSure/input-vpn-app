import 'dart:async';
import 'dart:math';

import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_stats.dart';
import 'package:input_vpn/services/vpn_service.dart';

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
