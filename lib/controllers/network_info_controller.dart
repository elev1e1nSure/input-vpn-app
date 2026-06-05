import 'package:flutter/foundation.dart';
import 'package:input_vpn/services/ip_service.dart';

/// Manages public IP and country code state.
class NetworkInfoController extends ChangeNotifier {
  String? _publicIp;
  String? _countryCode;

  String? get publicIp => _publicIp;
  String? get countryCode => _countryCode;

  Future<void> refresh() async {
    _publicIp = await IpService.fetchPublicIp();
    _countryCode = await IpService.fetchCountryCode();
    debugPrint('NetworkInfoController: publicIp=$_publicIp, countryCode=$_countryCode');
    notifyListeners();
  }

  void clear() {
    _publicIp = null;
    _countryCode = null;
    notifyListeners();
  }
}
