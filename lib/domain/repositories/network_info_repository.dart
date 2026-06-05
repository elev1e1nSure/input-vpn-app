import 'package:input_vpn/core/result.dart';

abstract class NetworkInfoRepository {
  Result<String?> getPublicIp();
  Result<String?> getCountryCode();
  Result<bool> getIsRefreshing();

  Result<void> refresh();
  Result<void> clear();
}
