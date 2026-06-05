import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';

class RefreshNetworkInfo {
  final NetworkInfoRepository repository;

  RefreshNetworkInfo(this.repository);

  Result<void> call() {
    return repository.refresh();
  }
}
