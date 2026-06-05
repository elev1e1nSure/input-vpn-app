import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';

class RemoveConfig {
  final VpnConfigRepository repository;

  RemoveConfig(this.repository);

  Result<void> call(String configId) {
    return repository.removeConfig(configId);
  }
}
