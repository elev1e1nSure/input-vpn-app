import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';

class RefreshSubscription {
  final VpnConfigRepository repository;

  RefreshSubscription(this.repository);

  Result<void> call(String configId) {
    return repository.refreshSubscriptionStats(configId);
  }
}
