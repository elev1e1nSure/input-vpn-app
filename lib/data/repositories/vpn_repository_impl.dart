import 'dart:async';

import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/singbox_vpn_service.dart';
import 'package:input_vpn/services/vpn_service.dart';
import 'package:input_vpn/domain/repositories/vpn_repository.dart';

class VpnRepositoryImpl implements VpnRepository {
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

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isConnecting => _isConnecting;

  @override
  bool get isProxyMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.proxyMode : false;
  }

  @override
  bool get isServiceMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.serviceMode : false;
  }

  @override
  bool get isReconnecting {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.isReconnecting : false;
  }

  @override
  int get reconnectAttempt {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.reconnectAttempt : 0;
  }

  @override
  Stream<ConnectionStatus> watchStatus() => _vpn.watchStatus();

  @override
  Future<void> connect(ParsedConfig config) => _vpn.connect(config);

  @override
  Future<void> disconnect() => _vpn.disconnect();

  @override
  Future<void> setProxyMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    if (_isConnected) {
      await disconnect();
    }
    vpn.setProxyMode(enabled);
  }

  @override
  Future<void> setServiceMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    if (_isConnected) {
      await disconnect();
    }
    vpn.setServiceMode(enabled);
  }

  @override
  void setDnsServers({required String remoteDns, required String directDns}) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    vpn.setDnsServers(remoteDns: remoteDns, directDns: directDns);
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    if (_isConnected) {
      _vpn.disconnect().ignore();
    }
    _vpn.dispose();
  }
}
