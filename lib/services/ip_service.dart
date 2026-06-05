import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching the current public IP address and country code.
class IpService {
  static final Dio _dio = Dio();

  /// Returns the current public IP or null on failure.
  static Future<String?> fetchPublicIp() async {
    try {
      final response = await _dio.get<String>(
        'https://api.ipify.org',
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final ip = response.data?.trim();
      if (ip != null && ip.isNotEmpty) return ip;
    } on Exception catch (_) {
      // Silently fail — IP is best-effort.
    }
    return null;
  }

  /// Returns the country code (ISO-3166 alpha-2) for the current public IP,
  /// or null on failure.
  static Future<String?> fetchCountryCode() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'http://ip-api.com/json/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final countryCode = response.data?['countryCode'] as String?;
      debugPrint(
          'IpService: countryCode response: $countryCode, full data: ${response.data}');
      if (countryCode != null && countryCode.isNotEmpty) return countryCode;
    } on Exception catch (e) {
      debugPrint('IpService: Failed to fetch country code: $e');
    }
    return null;
  }
}
