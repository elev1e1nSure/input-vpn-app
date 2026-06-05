import 'dart:async';

import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/vpn/windows/singbox_vpn_service.dart';
import 'package:input_vpn/services/vpn_service.dart';

class VpnRepositoryImpl implements VpnServiceRepository {
  VpnRepositoryImpl({required VpnService vpnService}) : _vpn = vpnService {
    _statusSub = _vpn.watchStatus().listen((status) {
      _isConnected = status is Connected;
      _isConnecting = status is Connecting;
    });
  }

  final VpnService _vpn;
  StreamSubscription<ConnectionStatus>? _statusSub;

  bool _isConnected = false;
  bool _isConnecting = false;

  bool get isConnected => _isConnected;

  bool get isConnecting => _isConnecting;

  bool get isProxyMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.proxyMode : false;
  }

  bool get isServiceMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.serviceMode : false;
  }

  bool get isReconnecting {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.isReconnecting : false;
  }

  int get reconnectAttempt {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.reconnectAttempt : 0;
  }

  @override
  Result<Stream<ConnectionStatus>> watchStatus() =>
      Result.ok(_vpn.watchStatus());

  @override
  Result<void> connect(ParsedConfig config) {
    _vpn.connect(config);
    return Result.ok(null);
  }

  @override
  Result<void> disconnect() {
    _vpn.disconnect();
    return Result.ok(null);
  }

  @override
  Result<void> dispose() {
    _statusSub?.cancel();
    if (_isConnected) {
      _vpn.disconnect().ignore();
    }
    _vpn.dispose();
    return Result.ok(null);
  }

  @override
  Result<bool> getIsConnected() => Result.ok(_isConnected);

  @override
  Result<bool> getIsConnecting() => Result.ok(_isConnecting);

  @override
  Result<bool> getIsProxyMode() => Result.ok(isProxyMode);

  @override
  Result<bool> getIsServiceMode() => Result.ok(isServiceMode);

  @override
  Result<bool> getIsReconnecting() => Result.ok(isReconnecting);

  @override
  Result<int> getReconnectAttempt() => Result.ok(reconnectAttempt);

  @override
  Result<void> setProxyMode(bool enabled) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return Result.ok(null);
    if (_isConnected) {
      disconnect();
    }
    vpn.setProxyMode(enabled);
    return Result.ok(null);
  }

  @override
  Result<void> setServiceMode(bool enabled) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return Result.ok(null);
    if (_isConnected) {
      disconnect();
    }
    vpn.setServiceMode(enabled);
    return Result.ok(null);
  }

  @override
  Result<void> setDnsServers(
      {required String remoteDns, required String directDns}) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return Result.ok(null);
    vpn.setDnsServers(remoteDns: remoteDns, directDns: directDns);
    return Result.ok(null);
  }
}
