import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';
import 'package:input_vpn/models/vpn_server.dart';

class SelectServer {
  SelectServer(this.repository);
  final VpnConfigRepository repository;

  Result<void> call(VpnServer server) {
    return repository.selectServer(server);
  }
}
