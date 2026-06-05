import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/config_repository.dart';
import 'package:input_vpn/domain/usecases/add_config.dart';
import 'package:input_vpn/domain/usecases/remove_config.dart';
import 'package:input_vpn/domain/usecases/update_config.dart';
import 'package:input_vpn/domain/usecases/refresh_subscription_stats.dart';
import 'package:input_vpn/models/config_type.dart';
import 'package:input_vpn/models/vpn_server.dart';
import 'package:input_vpn/presentation/cubits/config_state.dart';

class ConfigCubit extends Cubit<ConfigState> {
  ConfigCubit({
    required ConfigRepository configRepository,
    required AddConfig addConfig,
    required RemoveConfig removeConfig,
    required UpdateConfig updateConfig,
    required RefreshSubscriptionStats refreshSubscriptionStats,
  })  : _configRepository = configRepository,
        _addConfig = addConfig,
        _removeConfig = removeConfig,
        _updateConfig = updateConfig,
        _refreshSubscriptionStats = refreshSubscriptionStats {
    _loadState();
  }

  final ConfigRepository _configRepository;
  final AddConfig _addConfig;
  final RemoveConfig _removeConfig;
  final UpdateConfig _updateConfig;
  final RefreshSubscriptionStats _refreshSubscriptionStats;

  Future<void> _loadState() async {
    await _configRepository.loadState();
    emit(ConfigState(
      userConfigs: _configRepository.getUserConfigs(),
      userServers: _configRepository.getUserServers(),
    ));
  }

  Future<void> addConfig(String name, String raw, ConfigType type) async {
    emit(state.copyWith(isLoading: true));
    await _addConfig(name, raw, type);
    emit(ConfigState(
      userConfigs: _configRepository.getUserConfigs(),
      userServers: _configRepository.getUserServers(),
      isLoading: false,
    ));
  }

  Future<void> removeConfig(String configId) async {
    emit(state.copyWith(isLoading: true));
    await _removeConfig(configId);
    emit(ConfigState(
      userConfigs: _configRepository.getUserConfigs(),
      userServers: _configRepository.getUserServers(),
      isLoading: false,
    ));
  }

  Future<void> updateConfig(
      String configId, String newName, String newRawConfig) async {
    emit(state.copyWith(isLoading: true));
    await _updateConfig(configId, newName, newRawConfig);
    emit(ConfigState(
      userConfigs: _configRepository.getUserConfigs(),
      userServers: _configRepository.getUserServers(),
      isLoading: false,
    ));
  }

  Future<void> refreshSubscriptionStats(String configId) async {
    await _refreshSubscriptionStats(configId);
    emit(ConfigState(
      userConfigs: _configRepository.getUserConfigs(),
      userServers: _configRepository.getUserServers(),
    ));
  }

  VpnServer? getSelectedServer() => _configRepository.getSelectedServer();

  Future<void> selectServer(VpnServer server) async {
    await _configRepository.selectServer(server);
  }
}
