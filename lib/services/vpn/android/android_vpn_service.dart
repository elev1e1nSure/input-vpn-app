import 'dart:async';

import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_stats.dart';
import 'package:input_vpn/services/vpn_service.dart';

/// Stub VPN service for Android.
///
/// This is a placeholder implementation that throws [UnimplementedError]
/// for all methods. Real Android VPN implementation should be added later.
class AndroidVpnService implements VpnService {
  @override
  ConnectionStatus get status => const Disconnected();

  @override
  Stream<ConnectionStatus> watchStatus() async* {
    yield status;
  }

  @override
  Stream<VpnStats> watchStats() async* {
    yield VpnStats.empty;
  }

  @override
  Future<void> connect(ParsedConfig config) {
    throw UnimplementedError('Android VPN not yet implemented');
  }

  @override
  Future<void> disconnect() {
    throw UnimplementedError('Android VPN not yet implemented');
  }

  @override
  Future<void> reconnect(ParsedConfig config) {
    throw UnimplementedError('Android VPN not yet implemented');
  }

  @override
  Future<void> dispose() async {
    // No-op for stub
  }
}
