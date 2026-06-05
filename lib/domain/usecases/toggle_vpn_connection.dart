import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/parsed_config.dart';
import 'package:input_vpn/domain/repositories/vpn_service_repository.dart';

class ToggleVpnConnection {
  final VpnServiceRepository repository;

  ToggleVpnConnection(this.repository);

  Result<void> call(ParsedConfig? config) {
    final isConnected = repository.getIsConnected();
    final isConnecting = repository.getIsConnecting();

    return isConnected.when(
      onSuccess: (connected) {
        if (connected) {
          return repository.disconnect();
        }
        return isConnecting.when(
          onSuccess: (connecting) {
            if (!connecting && config != null) {
              return repository.connect(config);
            }
            return Result.ok(null);
          },
          onFailure: (msg, cause) => Result.err(msg, cause: cause),
        );
      },
      onFailure: (msg, cause) => Result.err(msg, cause: cause),
    );
  }
}
