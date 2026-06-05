import 'package:input_vpn/models/vpn_config.dart';
import 'package:input_vpn/models/vpn_server.dart';

class ConfigState {
  final List<VpnConfig> userConfigs;
  final List<VpnServer> userServers;
  final bool isLoading;

  const ConfigState({
    this.userConfigs = const [],
    this.userServers = const [],
    this.isLoading = false,
  });

  ConfigState copyWith({
    List<VpnConfig>? userConfigs,
    List<VpnServer>? userServers,
    bool? isLoading,
  }) {
    return ConfigState(
      userConfigs: userConfigs ?? this.userConfigs,
      userServers: userServers ?? this.userServers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
