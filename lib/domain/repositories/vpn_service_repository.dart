import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';

abstract class VpnServiceRepository {
  Result<Stream<ConnectionStatus>> watchStatus();

  /// Connect and await the real backend result. Returns a failure [Result]
  /// (never throws) when the underlying connect fails.
  Future<Result<void>> connect(ParsedConfig config);

  /// Disconnect and await the real backend result.
  Future<Result<void>> disconnect();

  Result<void> dispose();

  Result<bool> getIsConnected();
  Result<bool> getIsConnecting();
  Result<bool> getIsProxyMode();
  Result<bool> getIsServiceMode();
  Result<bool> getIsReconnecting();
  Result<int> getReconnectAttempt();

  Future<Result<void>> setProxyMode(bool enabled);
  Future<Result<void>> setServiceMode(bool enabled);
  Result<void> setDnsServers(
      {required String remoteDns, required String directDns});
}
