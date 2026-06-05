import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/vpn_server.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';

class SelectServer {
  final VpnConfigRepository repository;

  SelectServer(this.repository);

  Result<void> call(VpnServer server) {
    return repository.selectServer(server);
  }
}
