import 'package:input_vpn/services/ip_service.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';

class NetworkInfoRepositoryImpl implements NetworkInfoRepository {
  NetworkInfoRepositoryImpl();

  String? _publicIp;
  String? _countryCode;
  bool _isRefreshing = false;

  @override
  String? get publicIp => _publicIp;

  @override
  String? get countryCode => _countryCode;

  @override
  bool get isRefreshing => _isRefreshing;

  @override
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      _publicIp = await IpService.fetchPublicIp();
      _countryCode = await IpService.fetchCountryCode();
    } finally {
      _isRefreshing = false;
    }
  }

  @override
  void clear() {
    _publicIp = null;
    _countryCode = null;
  }
}
