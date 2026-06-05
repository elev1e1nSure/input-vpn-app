import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/parsed_config.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';

class ConnectVpn {
  final VpnServiceRepository repository;

  ConnectVpn(this.repository);

  Result<void> call(ParsedConfig config) {
    return repository.connect(config);
  }
}
