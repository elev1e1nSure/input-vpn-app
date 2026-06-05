import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_config.dart';
import 'package:input_vpn/models/vpn_server.dart';

abstract class VpnConfigRepository {
  Result<List<VpnConfig>> getUserConfigs();
  Result<List<VpnServer>> getUserServers();
  Result<VpnServer?> getSelectedServer();
  Result<ParsedConfig?> getParsedConfig(String serverId);

  Result<void> addConfig(String name, String raw, String type);
  Result<void> removeConfig(String configId);
  Result<void> updateConfig(
      String configId, String newName, String newRawConfig);
  Result<void> selectServer(VpnServer server);
  Result<void> refreshSubscriptionStats(String configId);

  Result<void> saveState();
  Result<void> loadState();
}
