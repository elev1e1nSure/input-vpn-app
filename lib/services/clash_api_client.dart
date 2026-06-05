import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:input_vpn/services/dio_factory.dart';

/// Small client for sing-box's built-in Clash API.
///
/// sing-box exposes a Clash-compatible REST + WebSocket API at the address
/// configured by `experimental.clash_api.external_controller` — by default
/// `127.0.0.1:9090` in this app.
///
/// We use two endpoints:
///   - `GET /version` -> {"version":"...", "premium":true}
///       Reliable readiness probe: returns 200 once sing-box is fully up.
///   - `GET /traffic` (streaming chunked JSON, one line per second)
///       {"up": [bytes/s], "down": [bytes/s]}
///
/// Reference:
///   https://sing-box.sagernet.org/configuration/experimental/clash-api/
class ClashApiClient {
  ClashApiClient({this.host = '127.0.0.1', this.port = 9090, Dio? dio})
      : _dio = dio ?? DioFactory.forClashApi();

  final String host;
  final int port;
  final Dio _dio;

  String get base => 'http://$host:$port';

  /// Wait until the Clash API responds (sing-box finished startup).
  /// Returns the server version string on success, throws after [timeout].
  Future<String> waitReady({
    Duration timeout = const Duration(seconds: 15),
    Duration retry = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastErr;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final res = await _dio.get<dynamic>('$base/version');
        if (res.statusCode == 200) {
          final data = res.data is Map ? res.data as Map : <String, dynamic>{};
          return (data['version'] ?? 'unknown').toString();
        }
      } catch (e) {
        lastErr = e;
      }
      await Future<void>.delayed(retry);
    }
    throw TimeoutException(
      'Clash API at $base did not become ready within $timeout (last error: $lastErr)',
    );
  }

  /// Quick check whether the API is reachable.
  Future<bool> isAlive() async {
    try {
      final res = await _dio.get<dynamic>(
        '$base/version',
        options: Options(receiveTimeout: const Duration(milliseconds: 500)),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Stream of upload/download bytes-per-second samples.
  /// One emission ~per second.
  Stream<TrafficSample> watchTraffic() async* {
    while (true) {
      try {
        final rs = await _dio.get<ResponseBody>(
          '$base/traffic',
          options: Options(responseType: ResponseType.stream),
        );
        final stream = rs.data!.stream;
        final lineStream =
            stream.map(utf8.decode).transform(const LineSplitter());
        await for (final line in lineStream) {
          if (line.trim().isEmpty) continue;
          try {
            final obj = jsonDecode(line) as Map<String, dynamic>;
            yield TrafficSample(
              upBps: (obj['up'] as num? ?? 0).toDouble(),
              downBps: (obj['down'] as num? ?? 0).toDouble(),
            );
          } catch (_) {
            // skip malformed line
          }
        }
      } catch (_) {
        // Connection dropped — wait and retry.
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  /// Polls the connections endpoint to estimate average latency.
  /// (sing-box doesn't expose a direct ping number; we approximate via the
  ///  Clash `proxies/{name}/delay` endpoint if available, otherwise return 0.)
  Future<int> measureLatency({
    String proxyName = 'proxy',
    String testUrl = 'http://www.gstatic.com/generate_204',
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '$base/proxies/$proxyName/delay',
        queryParameters: {
          'url': testUrl,
          'timeout': 5000,
        },
      );
      if (res.data is Map && (res.data as Map)['delay'] != null) {
        return ((res.data as Map)['delay'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  /// Ask sing-box to shut down (Clash extension). Not always available — fall
  /// back to OS-level TerminateProcess from SingBoxProcess if this fails.
  Future<void> requestShutdown() async {
    try {
      await _dio.post<dynamic>('$base/restart',
          options: Options(receiveTimeout: const Duration(seconds: 2)));
    } catch (_) {}
  }
}

class TrafficSample {
  const TrafficSample({required this.upBps, required this.downBps});
  final double upBps;
  final double downBps;
}
