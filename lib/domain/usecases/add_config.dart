import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';
import 'package:input_vpn/models/config_type.dart';

class AddConfig {
  final VpnConfigRepository repository;

  AddConfig(this.repository);

  Result<void> call(String name, String raw, ConfigType type) {
    return repository.addConfig(name, raw, type.name);
  }
}
