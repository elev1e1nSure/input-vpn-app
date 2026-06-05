import 'package:input_vpn/core/result.dart';

abstract class IpLookupRepository {
  Result<String> fetchPublicIp();
  Result<String> fetchCountryCode();
}
