import 'package:flutter/foundation.dart';
import 'package:input_vpn/services/ip_service.dart';

/// Manages public IP and country code state.
class NetworkInfoController extends ChangeNotifier {
  String? _publicIp;
  String? _countryCode;
  bool _isRefreshing = false;

  String? get publicIp => _publicIp;
  String? get countryCode => _countryCode;
  bool get isRefreshing => _isRefreshing;

  /// Fetches public IP and country code. Ignores concurrent calls.
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      _publicIp = await IpService.fetchPublicIp();
      _countryCode = await IpService.fetchCountryCode();
      debugPrint(
        'NetworkInfoController: publicIp=$_publicIp, countryCode=$_countryCode',
      );
      notifyListeners();
    } finally {
      _isRefreshing = false;
    }
  }

  void clear() {
    _publicIp = null;
    _countryCode = null;
    notifyListeners();
  }
}
