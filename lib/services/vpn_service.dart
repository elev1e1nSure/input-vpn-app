import 'dart:async';

import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_stats.dart';

/// Supported VPN platforms.
enum VpnPlatform {
  windows,
  android,
  mock,
}

/// Backend-agnostic VPN service contract.
///
/// The real implementation wraps a native engine (sing-box).
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
