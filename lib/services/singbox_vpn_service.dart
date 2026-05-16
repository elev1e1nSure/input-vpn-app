import 'dart:async';
import 'dart:io';

import 'package:input_vpn/models/connection_failure.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_stats.dart';
import 'package:input_vpn/services/clash_api_client.dart';
import 'package:input_vpn/services/singbox_config_builder.dart';
import 'package:input_vpn/services/singbox_process.dart';
import 'package:input_vpn/services/vpn_service.dart';

/// Real VPN backend for Windows: wraps `sing-box.exe` with a TUN device.
///
/// Lifecycle:
///   1. [connect] builds a sing-box config from [ParsedConfig] via
///      [SingBoxConfigBuilder], writes it to disk, spawns `sing-box.exe`
///      with UAC elevation (TUN requires admin), and waits for the Clash
///      API to become reachable.
///   2. Once ready -> emits [Connected]. A background poller drives
///      [VpnStats] from the Clash API traffic stream.
///   3. [disconnect] terminates the elevated sing-box process and emits
///      [Disconnected].
///
/// Falls back to a clear error if the bundled binaries are missing.
class SingBoxVpnService implements VpnService {
  SingBoxVpnService({
    SingBoxProcess? process,
    SingBoxConfigBuilder? configBuilder,
    ClashApiClient? clashApi,
    bool proxyMode = false,
    bool serviceMode = false,
    String remoteDns = 'tls://1.1.1.1',
    String directDns = '8.8.8.8',
  })  : _process = process ?? SingBoxProcess(),
        _remoteDnsServer = remoteDns,
        _directDnsServer = directDns,
        _config = configBuilder ??
            SingBoxConfigBuilder(
              proxyMode: proxyMode,
              remoteDnsServer: remoteDns,
              directDnsServer: directDns,
            ),
        _clash = clashApi ?? ClashApiClient(),
        _proxyMode = proxyMode,
        _serviceMode = serviceMode;

  final SingBoxProcess _process;
  SingBoxConfigBuilder _config;
  final ClashApiClient _clash;
  bool _proxyMode;
  bool _serviceMode;
  String _remoteDnsServer;
  String _directDnsServer;

  /// Whether sing-box is configured as a local SOCKS proxy (no TUN, no UAC).
  bool get proxyMode => _proxyMode;

  /// Whether to launch sing-box via Windows Service (no UAC after install).
  bool get serviceMode => _serviceMode;

  /// Toggle service mode. Takes effect at the NEXT connect().
  void setServiceMode(bool value) => _serviceMode = value;

  /// Toggle proxy mode. Takes effect at the NEXT connect().
  void setProxyMode(bool value) {
    if (_proxyMode == value) return;
    _proxyMode = value;
    _config = SingBoxConfigBuilder(
      proxyMode: value,
      remoteDnsServer: _remoteDnsServer,
      directDnsServer: _directDnsServer,
    );
  }

  void setDnsServers({required String remoteDns, required String directDns}) {
    if (_remoteDnsServer == remoteDns && _directDnsServer == directDns) {
      return;
    }
    _remoteDnsServer = remoteDns;
    _directDnsServer = directDns;
    _config = SingBoxConfigBuilder(
      proxyMode: _proxyMode,
      remoteDnsServer: remoteDns,
      directDnsServer: directDns,
    );
  }

  final _statusCtrl = StreamController<ConnectionStatus>.broadcast();
  final _statsCtrl = StreamController<VpnStats>.broadcast();
  ConnectionStatus _status = const Disconnected();
  StreamSubscription<TrafficSample>? _trafficSub;
  Timer? _liveCheckTimer;
  Timer? _latencyTimer;
  Timer? _reconnectTimer;
  int _lastLatencyMs = 0;

  /// Last config used for connect — kept for auto-reconnect.
  ParsedConfig? _lastConfig;
  int _reconnectAttempt = 0;
  static const int _maxReconnects = 3;
  static const List<Duration> _reconnectDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 15),
  ];

  /// Whether the service is currently in an auto-reconnect cycle.
  bool get isReconnecting => _reconnectAttempt > 0;
  int get reconnectAttempt => _reconnectAttempt;

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
    _lastConfig = config;
    _reconnectAttempt = 0;
    _setStatus(const Connecting());

    try {
      // 1) Pre-resolve the log path so sing-box writes to a file we own
      //    (ShellExecuteEx detaches stdout, so without this we'd be blind).
      final ws = await _process.prepareWorkDir();

      // 2) Generate config and start sing-box. TUN mode needs elevation
      //    (UAC prompt fires here); SOCKS test mode does not.
      final jsonStr = _config.build(config, logPath: ws.logPath);
      await _process.start(
        jsonStr,
        elevated: !_proxyMode && !_serviceMode,
        serviceMode: _serviceMode,
      );

      // 3) Wait for Clash API to come up, polling process aliveness too so
      //    we fail fast when sing-box exits with a bad config.
      await _waitReadyOrFail();

      // 4) Wire up traffic stream + liveness watchdog.
      _startTrafficPump();
      _startLivenessCheck();
      _startLatencyProbe();

      _setStatus(Connected(since: DateTime.now()));
    } on SingBoxStartException catch (e) {
      _setStatus(Disconnected(failure: UnexpectedFailure(e.message)));
      await _hardStop();
      rethrow;
    } on TimeoutException catch (e) {
      final tail = await _process.tailLog();
      final msg = 'sing-box did not become ready: ${e.message}\n\n'
          '--- sing-box log tail (${_process.logFile?.path}) ---\n$tail';
      _setStatus(Disconnected(failure: UnexpectedFailure(msg)));
      await _hardStop();
      throw UnexpectedFailure(msg);
    } catch (e) {
      final tail = await _process.tailLog();
      _setStatus(Disconnected(
        failure: UnexpectedFailure('$e\n\nsing-box log tail:\n$tail'),
      ));
      await _hardStop();
      rethrow;
    }
  }

  /// Polls the Clash API until it answers OR sing-box.exe exits.
  Future<void> _waitReadyOrFail({
    Duration overall = const Duration(seconds: 30),
  }) async {
    final deadline = DateTime.now().add(overall);
    while (DateTime.now().isBefore(deadline)) {
      // Fail-fast if the child process is gone.
      if (!await _process.isProcessAlive()) {
        final err = await _process.extractFatalError();
        throw UnexpectedFailure(
          'VPN engine failed to start.\n\n'
          'Details: $err\n\n'
          'If this persists, check the full log:\n'
          '${_process.logFile?.path ?? 'sing-box.log'}',
        );
      }
      if (await _clash.isAlive()) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    throw TimeoutException(
      'Clash API at ${_clash.base} did not answer within $overall',
    );
  }

  @override
  Future<void> disconnect() async {
    await _hardStop();
    _setStatus(const Disconnected());
  }

  @override
  Future<void> reconnect(ParsedConfig config) async {
    await disconnect();
    await connect(config);
  }

  Future<void> _hardStop() async {
    await _trafficSub?.cancel();
    _liveCheckTimer?.cancel();
    _latencyTimer?.cancel();
    _reconnectTimer?.cancel();
    _trafficSub = null;
    _liveCheckTimer = null;
    _latencyTimer = null;
    _reconnectTimer = null;
    _statsCtrl.add(VpnStats.empty);
    await _process.stop();
  }

  void _startTrafficPump() {
    _trafficSub?.cancel();
    _trafficSub = _clash.watchTraffic().listen((t) {
      _statsCtrl.add(VpnStats(
        downloadBytesPerSec: t.downBps,
        uploadBytesPerSec: t.upBps,
        pingMs: _lastLatencyMs,
      ));
    });
  }

  /// If the child process dies unexpectedly, try to reconnect with
  /// exponential backoff up to [_maxReconnects] times.
  void _startLivenessCheck() {
    _liveCheckTimer?.cancel();
    _liveCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!await _process.isProcessAlive() && _status is Connected) {
        await _hardStop();
        _scheduleReconnect();
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final cfg = _lastConfig;
    if (cfg == null || _reconnectAttempt >= _maxReconnects) {
      _reconnectAttempt = 0;
      _setStatus(const Disconnected(
        failure: UnexpectedFailure(
          'sing-box exited unexpectedly and could not reconnect. '
          'See sing-box.log for details.',
        ),
      ));
      return;
    }

    final delay = _reconnectDelays[_reconnectAttempt];
    _reconnectAttempt++;
    _setStatus(const Connecting());
    _reconnectTimer = Timer(delay, () async {
      try {
        final ws = await _process.prepareWorkDir();
        final jsonStr = _config.build(cfg, logPath: ws.logPath);
        await _process.start(
          jsonStr,
          elevated: !_proxyMode && !_serviceMode,
          serviceMode: _serviceMode,
        );
        await _waitReadyOrFail();
        _startTrafficPump();
        _startLivenessCheck();
        _startLatencyProbe();
        _reconnectAttempt = 0;
        _setStatus(Connected(since: DateTime.now()));
      } catch (_) {
        await _hardStop();
        _scheduleReconnect();
      }
    });
  }

  void _startLatencyProbe() {
    _latencyTimer?.cancel();
    // First probe immediately, then every 15s.
    _probeLatency();
    _latencyTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _probeLatency();
    });
  }

  Future<void> _probeLatency() async {
    final ms = await _clash.measureLatency();
    if (ms > 0) _lastLatencyMs = ms;
  }

  @override
  Future<void> dispose() async {
    await _hardStop();
    await _statusCtrl.close();
    await _statsCtrl.close();
  }

  /// Whether this backend can run on the current OS.
  static bool get isSupported => Platform.isWindows;
}
