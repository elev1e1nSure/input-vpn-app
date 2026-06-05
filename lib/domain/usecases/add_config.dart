import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';

class AddConfig {
  final VpnConfigRepository repository;

  AddConfig(this.repository);

  Result<void> call(String name, String raw, String type) {
    return repository.addConfig(name, raw, type);
  }
}
