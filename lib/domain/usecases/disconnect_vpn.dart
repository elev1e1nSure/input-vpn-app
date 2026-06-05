import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';

class DisconnectVpn {
  final VpnServiceRepository repository;

  DisconnectVpn(this.repository);

  Result<void> call() {
    return repository.disconnect();
  }
}
