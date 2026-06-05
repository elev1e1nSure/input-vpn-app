import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/vpn_repository.dart';
import 'package:input_vpn/domain/usecases/toggle_vpn_connection.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_server.dart';
import 'package:input_vpn/presentation/cubits/vpn_state.dart';

class VpnCubit extends Cubit<VpnState> {
  VpnCubit({
    required VpnRepository vpnRepository,
    required ToggleVpnConnection toggleVpnConnection,
  })  : _vpnRepository = vpnRepository,
        _toggleVpnConnection = toggleVpnConnection {
    _statusSub = _vpnRepository.watchStatus().listen(_onStatusChanged);
  }

  final VpnRepository _vpnRepository;
  final ToggleVpnConnection _toggleVpnConnection;
  StreamSubscription<ConnectionStatus>? _statusSub;

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _vpnRepository.dispose();
    return super.close();
  }

  void _onStatusChanged(ConnectionStatus status) {
    emit(state.copyWith(
      connectionStatus: status,
      isReconnecting: _vpnRepository.isReconnecting,
      reconnectAttempt: _vpnRepository.reconnectAttempt,
    ));
  }

  Future<void> toggleConnection(ParsedConfig? config) async {
    if (state.isConnecting) return;
    await _toggleVpnConnection(config);
  }

  Future<void> setProxyMode(bool enabled) async {
    await _vpnRepository.setProxyMode(enabled);
    emit(state.copyWith(isProxyMode: _vpnRepository.isProxyMode));
  }

  Future<void> setServiceMode(bool enabled) async {
    await _vpnRepository.setServiceMode(enabled);
    emit(state.copyWith(isServiceMode: _vpnRepository.isServiceMode));
  }

  void selectServer(VpnServer server) {
    emit(state.copyWith(selectedServer: server));
  }

  void applyDns(List<String> servers) {
    final remote = servers.isNotEmpty ? 'tls://${servers.first}' : 'tls://1.1.1.1';
    final direct = servers.length > 1 ? servers[1] : '8.8.8.8';
    _vpnRepository.setDnsServers(remoteDns: remote, directDns: direct);
  }
}
