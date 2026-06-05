import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';
import 'package:input_vpn/models/parsed_config.dart';

class ConnectVpn {
  ConnectVpn(this.repository);
  final VpnServiceRepository repository;

  Result<void> call(ParsedConfig config) {
    return repository.connect(config);
  }
}
