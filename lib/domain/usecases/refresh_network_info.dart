import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';

class RefreshNetworkInfo {
  RefreshNetworkInfo(this.repository);
  final NetworkInfoRepository repository;

  Result<void> call() {
    return repository.refresh();
  }
}
