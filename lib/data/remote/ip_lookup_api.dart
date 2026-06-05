import 'package:dio/dio.dart';

/// Remote API for public IP and geolocation lookups.
class IpLookupApi {
  IpLookupApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Returns the current public IPv4 address or null on failure.
  Future<String?> fetchPublicIp() async {
    final response = await _dio.get<String>(
      'https://api.ipify.org',
      options: Options(
        responseType: ResponseType.plain,
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final ip = response.data?.trim();
    return (ip != null && ip.isNotEmpty) ? ip : null;
  }

  /// Returns the ISO-3166 alpha-2 country code for the current IP or null.
  Future<String?> fetchCountryCode() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'http://ip-api.com/json/',
      options: Options(
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
    final countryCode = response.data?['countryCode'] as String?;
    return (countryCode != null && countryCode.isNotEmpty) ? countryCode : null;
  }
}
