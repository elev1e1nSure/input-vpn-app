import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/vpn_server.dart';

class VpnState {
  const VpnState({
    this.connectionStatus = const Disconnected(),
    this.selectedServer,
    this.isProxyMode = false,
    this.isServiceMode = false,
    this.isReconnecting = false,
    this.reconnectAttempt = 0,
  });
  final ConnectionStatus connectionStatus;
  final VpnServer? selectedServer;
  final bool isProxyMode;
  final bool isServiceMode;
  final bool isReconnecting;
  final int reconnectAttempt;

  bool get isConnected => connectionStatus is Connected;
  bool get isConnecting => connectionStatus is Connecting;

  VpnState copyWith({
    ConnectionStatus? connectionStatus,
    VpnServer? selectedServer,
    bool? isProxyMode,
    bool? isServiceMode,
    bool? isReconnecting,
    int? reconnectAttempt,
  }) {
    return VpnState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      selectedServer: selectedServer ?? this.selectedServer,
      isProxyMode: isProxyMode ?? this.isProxyMode,
      isServiceMode: isServiceMode ?? this.isServiceMode,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
    );
  }
}
