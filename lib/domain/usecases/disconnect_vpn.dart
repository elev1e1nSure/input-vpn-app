import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';

class DisconnectVpn {
  DisconnectVpn(this.repository);
  final VpnServiceRepository repository;

  Future<Result<void>> call() {
    return repository.disconnect();
  }
}
