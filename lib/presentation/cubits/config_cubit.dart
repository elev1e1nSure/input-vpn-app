import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';
import 'package:input_vpn/domain/usecases/add_config.dart';
import 'package:input_vpn/domain/usecases/refresh_subscription.dart';
import 'package:input_vpn/domain/usecases/remove_config.dart';
import 'package:input_vpn/domain/usecases/update_config.dart';
import 'package:input_vpn/models/config_type.dart';
import 'package:input_vpn/models/vpn_config.dart';
import 'package:input_vpn/models/vpn_server.dart';
import 'package:input_vpn/presentation/cubits/config_state.dart';

class ConfigCubit extends Cubit<ConfigState> {
  ConfigCubit({
    required VpnConfigRepository configRepository,
    required AddConfig addConfig,
    required RemoveConfig removeConfig,
    required UpdateConfig updateConfig,
    required RefreshSubscription refreshSubscription,
  })  : _configRepository = configRepository,
        _addConfig = addConfig,
        _removeConfig = removeConfig,
        _updateConfig = updateConfig,
        _refreshSubscription = refreshSubscription,
        super(const ConfigState()) {
    _loadState();
  }

  final VpnConfigRepository _configRepository;
  final AddConfig _addConfig;
  final RemoveConfig _removeConfig;
  final UpdateConfig _updateConfig;
  final RefreshSubscription _refreshSubscription;

  Future<void> _loadState() async {
    _configRepository.loadState();
    final userConfigsResult = _configRepository.getUserConfigs();
    final userServersResult = _configRepository.getUserServers();
    emit(ConfigState(
      userConfigs: userConfigsResult.getOrElse(const <VpnConfig>[]),
      userServers: userServersResult.getOrElse(const <VpnServer>[]),
    ));
  }

  Future<void> addConfig(String name, String raw, ConfigType type) async {
    emit(state.copyWith(isLoading: true));
    _addConfig(name, raw, type);
    final userConfigsResult = _configRepository.getUserConfigs();
    final userServersResult = _configRepository.getUserServers();
    emit(ConfigState(
      userConfigs: userConfigsResult.getOrElse(const <VpnConfig>[]),
      userServers: userServersResult.getOrElse(const <VpnServer>[]),
    ));
  }

  Future<void> removeConfig(String configId) async {
    emit(state.copyWith(isLoading: true));
    _removeConfig(configId);
    final userConfigsResult = _configRepository.getUserConfigs();
    final userServersResult = _configRepository.getUserServers();
    emit(ConfigState(
      userConfigs: userConfigsResult.getOrElse(const <VpnConfig>[]),
      userServers: userServersResult.getOrElse(const <VpnServer>[]),
    ));
  }

  Future<void> updateConfig(
      String configId, String newName, String newRawConfig) async {
    emit(state.copyWith(isLoading: true));
    _updateConfig(configId, newName, newRawConfig);
    final userConfigsResult = _configRepository.getUserConfigs();
    final userServersResult = _configRepository.getUserServers();
    emit(ConfigState(
      userConfigs: userConfigsResult.getOrElse(const <VpnConfig>[]),
      userServers: userServersResult.getOrElse(const <VpnServer>[]),
    ));
  }

  Future<void> refreshSubscriptionStats(String configId) async {
    _refreshSubscription(configId);
    final userConfigsResult = _configRepository.getUserConfigs();
    final userServersResult = _configRepository.getUserServers();
    emit(ConfigState(
      userConfigs: userConfigsResult.getOrElse(const <VpnConfig>[]),
      userServers: userServersResult.getOrElse(const <VpnServer>[]),
    ));
  }

  VpnServer? getSelectedServer() {
    final result = _configRepository.getSelectedServer();
    return result.value;
  }

  Future<void> selectServer(VpnServer server) async {
    _configRepository.selectServer(server);
  }
}
