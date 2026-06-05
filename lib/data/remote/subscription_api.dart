import 'package:dio/dio.dart';
import 'package:input_vpn/services/dio_factory.dart';

/// Remote API for downloading subscription content.
class SubscriptionApi {
  SubscriptionApi({Dio? dio}) : _dio = dio ?? DioFactory.forSubscriptions();

  final Dio _dio;

  /// Download subscription content from [url].
  /// Returns the raw body and response headers on success.
  Future<({String body, Map<String, String> headers})> fetch(
    String url, {
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get<String>(
      url,
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.plain),
    );
    final body = res.data ?? '';
    final responseHeaders = <String, String>{};
    res.headers.forEach((k, v) {
      if (v.isNotEmpty) responseHeaders[k.toLowerCase()] = v.first;
    });
    return (body: body, headers: responseHeaders);
  }
}
