import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:input_vpn/models/connection_failure.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/platform/windows/tray_manager.dart';
import 'package:input_vpn/services/vpn/windows/singbox_vpn_service.dart';
import 'package:input_vpn/services/vpn_service.dart';

/// Manages the VPN connection lifecycle, status transitions,
/// and SingBox-specific modes (proxy / service).
class VpnConnectionController extends ChangeNotifier {
  VpnConnectionController({
    required VpnService vpnService,
    this.onConnecting,
    this.onConnected,
    this.onDisconnected,
  }) : _vpn = vpnService {
    _statusSub = _vpn.watchStatus().listen(_onStatus);
  }

  final VpnService _vpn;
  final void Function(String serverName)? onConnecting;
  final void Function(String serverName, String? serverCity)? onConnected;
  final void Function(ConnectionFailure? failure)? onDisconnected;

  StreamSubscription<ConnectionStatus>? _statusSub;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisconnecting = false;
  bool _operationInProgress = false;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isDisconnecting => _isDisconnecting;

  /// Whether the backend is currently in an auto-reconnect cycle.
  bool get isReconnecting {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.isReconnecting : false;
  }

  int get reconnectAttempt {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.reconnectAttempt : 0;
  }

  /// Whether the backend is running in SOCKS-proxy mode (no TUN).
  bool get isProxyMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.proxyMode : false;
  }

  /// Whether the backend uses Windows Service mode.
  bool get isServiceMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.serviceMode : false;
  }

  /// Toggle between SOCKS proxy and full TUN. Disconnects first if needed.
  Future<void> setProxyMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    if (_isConnected) {
      await disconnect();
    }
    vpn.setProxyMode(enabled);
    notifyListeners();
  }

  /// Toggle Windows Service mode. Disconnects first if needed.
  Future<void> setServiceMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    if (_isConnected) {
      await disconnect();
    }
    vpn.setServiceMode(enabled);
    notifyListeners();
  }

  /// Apply DNS servers to the underlying sing-box backend.
  void applyDns(List<String> servers) {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    final remote =
        servers.isNotEmpty ? 'tls://${servers.first}' : 'tls://1.1.1.1';
    final direct = servers.length > 1 ? servers[1] : '8.8.8.8';
    vpn.setDnsServers(remoteDns: remote, directDns: direct);
  }

  /// Connect using [parsedConfig]. State transitions are delivered
  /// via [watchStatus]. Ignores concurrent calls.
  Future<void> connect(ParsedConfig parsedConfig) async {
    if (_isConnected || _isConnecting || _operationInProgress) return;
    _operationInProgress = true;
    try {
      await _vpn.connect(parsedConfig);
    } finally {
      _operationInProgress = false;
    }
  }

  /// Disconnect the active VPN session. Ignores concurrent calls.
  Future<void> disconnect() async {
    if (_isDisconnecting || !_isConnected || _operationInProgress) return;
    _isDisconnecting = true;
    _operationInProgress = true;
    notifyListeners();
    try {
      await _vpn.disconnect();
    } finally {
      _operationInProgress = false;
      // _isDisconnecting is cleared by _onStatus or here as fallback
      _isDisconnecting = false;
      notifyListeners();
    }
  }

  /// Toggle between connected and disconnected states.
  Future<void> toggle(ParsedConfig? parsedConfig) async {
    if (_operationInProgress) return;
    if (_isConnected) {
      await disconnect();
      return;
    }
    if (_isConnecting) return;
    if (parsedConfig == null) return;
    await connect(parsedConfig);
  }

  /// Expose the raw status stream for widgets that need session timing.
  Stream<ConnectionStatus> get statusStream => _vpn.watchStatus();

  void _onStatus(ConnectionStatus status) {
    switch (status) {
      case Connecting():
        _isConnecting = true;
        _isConnected = false;
        TrayManager.updateTooltip('Connecting...');
        notifyListeners();
      case Connected():
        _isConnecting = false;
        _isConnected = true;
        _isDisconnecting = false;
        TrayManager.updateTooltip('Connected');
        notifyListeners();
      case Disconnected(failure: final f):
        _isConnecting = false;
        _isDisconnecting = false;
        _isConnected = false;
        TrayManager.updateTooltip('Disconnected');
        notifyListeners();
        if (f != null) {
          AppLogger.error('Disconnected with error: ${f.message}');
        } else {
          AppLogger.info('Disconnected');
        }
    }
    onDisconnected?.call(status is Disconnected ? status.failure : null);
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    if (_isConnected) {
      _vpn.disconnect().ignore();
    }
    _vpn.dispose();
    super.dispose();
  }
}
