import 'package:dio/dio.dart';

/// Centralized [Dio] factory so timeout defaults and interceptors
/// do not drift between call sites.
class DioFactory {
  DioFactory._();

  /// Short timeouts for the local Clash API (localhost:9090).
  static Dio forClashApi() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 5),
      ));

  /// Long timeouts for external subscription downloads.
  static Dio forSubscriptions() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        followRedirects: true,
        responseType: ResponseType.plain,
        headers: {
          // Generic UA — many sub endpoints serve different bodies
          // depending on User-Agent.
          'User-Agent': 'InputVPN/1.0',
        },
      ));
}
