import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';
import 'package:input_vpn/models/parsed_config.dart';

class ToggleVpnConnection {
  ToggleVpnConnection(this.repository);
  final VpnServiceRepository repository;

  Future<Result<void>> call(ParsedConfig? config) async {
    final connected = repository.getIsConnected().getOrElse(false);
    if (connected) {
      return repository.disconnect();
    }
    final connecting = repository.getIsConnecting().getOrElse(false);
    if (!connecting && config != null) {
      return repository.connect(config);
    }
    return const Result.ok(null);
  }
}
