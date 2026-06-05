import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';

abstract class VpnServiceRepository {
  Result<Stream<ConnectionStatus>> watchStatus();
  Result<void> connect(ParsedConfig config);
  Result<void> disconnect();
  Result<void> dispose();

  Result<bool> getIsConnected();
  Result<bool> getIsConnecting();
  Result<bool> getIsProxyMode();
  Result<bool> getIsServiceMode();
  Result<bool> getIsReconnecting();
  Result<int> getReconnectAttempt();

  Result<void> setProxyMode(bool enabled);
  Result<void> setServiceMode(bool enabled);
  Result<void> setDnsServers({required String remoteDns, required String directDns});
}
