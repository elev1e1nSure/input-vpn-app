import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_stats.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/singbox_vpn_service.dart';
import 'package:input_vpn/services/tray_manager.dart';
import 'package:input_vpn/services/vpn_service.dart';

class VpnManager extends ChangeNotifier {
  VpnManager({required VpnService vpnService}) : _vpn = vpnService {
    _statusSub = _vpn.watchStatus().listen(_onStatus);
  }

  final VpnService _vpn;
  StreamSubscription<ConnectionStatus>? _statusSub;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  String? _lastError;
  Timer? _errorTimer;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isDisconnecting => _isDisconnecting;
  String? get lastError => _lastError;

  Stream<ConnectionStatus> get statusStream => _vpn.watchStatus();
  Stream<VpnStats> get statsStream => _vpn.watchStats();

  bool get isReconnecting {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.isReconnecting : false;
  }

  int get reconnectAttempt {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.reconnectAttempt : 0;
  }

  bool get isProxyMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.proxyMode : false;
  }

  bool get isServiceMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.serviceMode : false;
  }

  void setProxyMode(bool enabled) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    vpn.setProxyMode(enabled);
    notifyListeners();
  }

  void setServiceMode(bool enabled) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    vpn.setServiceMode(enabled);
    notifyListeners();
  }

  void setDnsServers({required String remoteDns, required String directDns}) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    vpn.setDnsServers(remoteDns: remoteDns, directDns: directDns);
  }

  Future<void> connect(ParsedConfig config) async {
    if (_isConnected || _isConnecting) return;
    _isConnecting = true;
    notifyListeners();

    try {
      await _vpn.connect(config);
    } catch (e) {
      _isConnecting = false;
      _lastError = e.toString();
      _scheduleErrorClear();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_isDisconnecting) return;
    _isDisconnecting = true;
    notifyListeners();

    try {
      await _vpn.disconnect();
    } finally {
      _isDisconnecting = false;
      notifyListeners();
    }
  }

  Future<void> toggleConnection(ParsedConfig? config) async {
    if (config == null) return;
    if (_isConnected) {
      await disconnect();
    } else if (!_isConnecting) {
      await connect(config);
    }
  }

  void _onStatus(ConnectionStatus status) {
    switch (status) {
      case Connecting():
        _isConnecting = true;
        _isConnected = false;
        TrayManager.updateTooltip('Connecting...');
        AppLogger.info('Connecting to VPN');
      case Connected():
        _isConnecting = false;
        _isConnected = true;
        TrayManager.updateTooltip('Connected');
        AppLogger.info('Connected to VPN');
      case Disconnected(failure: final f):
        _isConnecting = false;
        _isDisconnecting = false;
        _isConnected = false;
        if (f != null) {
          _lastError = f.message;
          _scheduleErrorClear();
          AppLogger.error('Disconnected with error: ${f.message}');
        } else {
          AppLogger.info('Disconnected');
        }
        TrayManager.updateTooltip('Disconnected');
    }
    notifyListeners();
  }

  void _scheduleErrorClear() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), clearError);
  }

  void clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _statusSub?.cancel();
    _vpn.dispose();
    super.dispose();
  }
}
