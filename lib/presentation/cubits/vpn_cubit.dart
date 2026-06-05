import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';
import 'package:input_vpn/domain/usecases/toggle_vpn_connection.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_server.dart';
import 'package:input_vpn/presentation/cubits/vpn_state.dart';

class VpnCubit extends Cubit<VpnState> {
  VpnCubit({
    required VpnServiceRepository vpnRepository,
    required ToggleVpnConnection toggleVpnConnection,
  })  : _vpnRepository = vpnRepository,
        _toggleVpnConnection = toggleVpnConnection,
        super(const VpnState()) {
    final watchResult = _vpnRepository.watchStatus();
    if (watchResult.isSuccess) {
      _statusSub = watchResult.value.listen(_onStatusChanged);
    }
  }

  final VpnServiceRepository _vpnRepository;
  final ToggleVpnConnection _toggleVpnConnection;
  StreamSubscription<ConnectionStatus>? _statusSub;

  @override
  Future<void> close() {
    _statusSub?.cancel();
    _vpnRepository.dispose();
    return super.close();
  }

  void _onStatusChanged(ConnectionStatus status) {
    final isReconnectingResult = _vpnRepository.getIsReconnecting();
    final reconnectAttemptResult = _vpnRepository.getReconnectAttempt();
    emit(state.copyWith(
      connectionStatus: status,
      isReconnecting: isReconnectingResult.getOrElse(false),
      reconnectAttempt: reconnectAttemptResult.getOrElse(0),
    ));
  }

  Future<void> toggleConnection(ParsedConfig? config) async {
    if (state.isConnecting) return;
    await _toggleVpnConnection(config);
  }

  Future<void> setProxyMode(bool enabled) async {
    _vpnRepository.setProxyMode(enabled);
    final result = _vpnRepository.getIsProxyMode();
    emit(state.copyWith(isProxyMode: result.getOrElse(false)));
  }

  Future<void> setServiceMode(bool enabled) async {
    _vpnRepository.setServiceMode(enabled);
    final result = _vpnRepository.getIsServiceMode();
    emit(state.copyWith(isServiceMode: result.getOrElse(false)));
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
