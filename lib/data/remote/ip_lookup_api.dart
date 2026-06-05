import 'package:dio/dio.dart';
import 'package:input_vpn/core/result.dart';

/// Remote API for public IP and geolocation lookups.
class IpLookupApi {
  IpLookupApi({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Returns the current public IPv4 address.
  Future<Result<String>> fetchPublicIp() async {
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
      if (ip != null && ip.isNotEmpty) {
        return Result.ok(ip);
      }
      return const Result.err('Empty IP response');
    } on DioException catch (e) {
      return Result.err('IP lookup failed: ${e.type}');
    } on Exception catch (e) {
      return Result.err('IP lookup failed: $e');
    }
  }

  /// Returns the ISO-3166 alpha-2 country code for the current IP.
  Future<Result<String>> fetchCountryCode() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'http://ip-api.com/json/',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final countryCode = response.data?['countryCode'] as String?;
      if (countryCode != null && countryCode.isNotEmpty) {
        return Result.ok(countryCode);
      }
      return const Result.err('Empty country code');
    } on DioException catch (e) {
      return Result.err('Country lookup failed: ${e.type}');
    } on Exception catch (e) {
      return Result.err('Country lookup failed: $e');
    }
  }
}
