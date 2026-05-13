import 'package:dio/dio.dart';

/// Service for fetching the current public IP address.
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
    } catch (_) {
      // Silently fail — IP is best-effort.
    }
    return null;
  }
}
