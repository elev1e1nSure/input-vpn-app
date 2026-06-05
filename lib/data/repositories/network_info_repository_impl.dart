import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';
import 'package:input_vpn/services/ip_service.dart';

class NetworkInfoRepositoryImpl implements NetworkInfoRepository {
  NetworkInfoRepositoryImpl();

  String? _publicIp;
  String? _countryCode;
  bool _isRefreshing = false;

  @override
  Result<String?> getPublicIp() => Result.ok(_publicIp);

  @override
  Result<String?> getCountryCode() => Result.ok(_countryCode);

  @override
  Result<bool> getIsRefreshing() => Result.ok(_isRefreshing);

  @override
  Result<void> refresh() {
    if (_isRefreshing) return const Result.ok(null);
    _isRefreshing = true;
    try {
      _publicIp = IpService.fetchPublicIp() as String?;
      _countryCode = IpService.fetchCountryCode() as String?;
    } finally {
      _isRefreshing = false;
    }
    return const Result.ok(null);
  }

  @override
  Result<void> clear() {
    _publicIp = null;
    _countryCode = null;
    return const Result.ok(null);
  }
}
