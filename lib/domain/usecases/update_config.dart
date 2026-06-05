import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';

class UpdateConfig {
  UpdateConfig(this.repository);
  final VpnConfigRepository repository;

  Result<void> call(String configId, String newName, String newRawConfig) {
    return repository.updateConfig(configId, newName, newRawConfig);
  }
}
