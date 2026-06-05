import 'package:dio/dio.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/dio_factory.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';

/// Downloads and parses subscription URLs into a list of [ParsedConfig].
///
/// Name-extraction hierarchy (HTTP headers → URL fragment → fallback)
/// is preserved. Subscription HTTP headers (`profile-title`, `content-disposition`,
/// `subscription-userinfo`) are exposed via [SubscriptionResult.headers].
class SubscriptionService {
  SubscriptionService({Dio? dio}) : _dio = dio ?? DioFactory.forSubscriptions();

  final Dio _dio;

  /// Parse subscription content already in memory (no network call).
  SubscriptionResult parseContent(String content, {String? sourceUrl}) {
    final decoded = safeDecodeBase64(content);
    final headers = _parseHeaderComments(decoded);
    final lines = decoded
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') && !l.startsWith('//'))
        .toList();

    final configs = <ParsedConfig>[];
    final failures = <({String line, String error})>[];

    for (final line in lines) {
      try {
        configs.add(VpnUrlParser.parse(line));
      } on Exception catch (e) {
        failures.add((line: line, error: e.toString()));
      }
    }

    return SubscriptionResult(
      configs: configs,
      failures: failures,
      headers: headers,
      title: _extractTitle(headers, sourceUrl),
      sourceUrl: sourceUrl,
    );
  }

  /// Download a subscription URL and parse it.
  Future<SubscriptionResult> fetch(String url,
      {CancelToken? cancelToken}) async {
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
    final parsed = parseContent(body, sourceUrl: url);
    // Merge response headers (subscription-userinfo, profile-title come from
    // HTTP headers in most providers).
    final merged = <String, String>{...parsed.headers};
    for (final entry in responseHeaders.entries) {
      if (_allowedProfileHeaders.contains(entry.key)) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return SubscriptionResult(
      configs: parsed.configs,
      failures: parsed.failures,
      headers: merged,
      title: _extractTitle(merged, url),
      sourceUrl: url,
    );
  }

  // Header allow-list for subscription profile metadata.
  static const _allowedProfileHeaders = {
    'profile-title',
    'content-disposition',
    'subscription-userinfo',
    'profile-update-interval',
    'support-url',
    'profile-web-page-url',
  };

  /// Parse `# key: value` and `// key: value` style lines from the first 10
  /// lines of the body.
  static Map<String, String> _parseHeaderComments(String content) {
    final headers = <String, String>{};
    final lines = content.split(RegExp(r'\r?\n'));
    final n = lines.length < 10 ? lines.length : 10;
    for (var i = 0; i < n; i++) {
      final line = lines[i];
      if (line.startsWith('#') || line.startsWith('//')) {
        final colon = line.indexOf(':');
        if (colon == -1) continue;
        final key = line
            .substring(0, colon)
            .replaceFirst(RegExp(r'^#|//'), '')
            .trim()
            .toLowerCase();
        final value = line.substring(colon + 1).trim();
        if (_allowedProfileHeaders.contains(key) && value.isNotEmpty) {
          headers[key] = value;
        }
      }
    }
    return headers;
  }

  /// Derive a human-readable title from headers or URL.
  static String? _extractTitle(Map<String, String> headers, String? url) {
    if (headers['profile-title'] case final t? when t.isNotEmpty) {
      // Handle `base64:...` prefixed titles
      if (t.startsWith('base64:')) {
        return safeDecodeBase64(t.substring('base64:'.length));
      }
      return t;
    }
    if (headers['content-disposition'] case final cd? when cd.isNotEmpty) {
      final match = RegExp(r'filename="([^"]*)"').firstMatch(cd);
      if (match != null) return match.group(1);
    }
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        if (uri.fragment.isNotEmpty) {
          return Uri.decodeComponent(uri.fragment);
        }
        if (uri.pathSegments.isNotEmpty) {
          final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
          if (segments.isEmpty) return null;

          // Helper to check if string looks like a token (long random string without separators)
          bool looksLikeToken(String s) {
            // Token: long (>15 chars) or contains only alphanumeric without underscores/hyphens
            if (s.length > 20) return true;
            if (s.length < 5) return false;
            // If has no separators, likely a token
            return !s.contains('_') && !s.contains('-') && !s.contains(' ');
          }

          String result;
          if (segments.length >= 2 && looksLikeToken(segments.last)) {
            // Use second-to-last if last looks like a token (e.g., /name/uuid)
            result = segments[segments.length - 2];
          } else {
            // Use last segment
            result = segments.last;
          }

          return result.replaceFirst(RegExp(r'\.(json|yaml|yml|txt)$'), '');
        }
      }
    }
    return null;
  }
}

class SubscriptionResult {
  const SubscriptionResult({
    required this.configs,
    required this.failures,
    required this.headers,
    this.title,
    this.sourceUrl,
  });

  final List<ParsedConfig> configs;
  final List<({String line, String error})> failures;
  final Map<String, String> headers;
  final String? title;
  final String? sourceUrl;

  /// Parsed `subscription-userinfo` header. Returns null if absent.
  ///
  /// Example header value:
  /// `upload=12345; download=67890; total=10737418240; expire=1735689600`
  SubscriptionInfo? get info {
    final raw = headers['subscription-userinfo'];
    if (raw == null || raw.isEmpty) return null;
    final map = <String, int>{};
    for (final part in raw.split(';')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final v = int.tryParse(kv[1].trim());
      if (v != null) map[kv[0].trim()] = v;
    }
    if (!map.containsKey('upload') || !map.containsKey('download')) return null;
    return SubscriptionInfo(
      upload: map['upload']!,
      download: map['download']!,
      total: map['total'] ?? 0,
      expire: (map['expire'] ?? 0) == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['expire']! * 1000),
    );
  }

  bool get isEmpty => configs.isEmpty;
  bool get isNotEmpty => configs.isNotEmpty;
}

class SubscriptionInfo {
  const SubscriptionInfo({
    required this.upload,
    required this.download,
    required this.total,
    this.expire,
  });

  final int upload;
  final int download;
  final int total;
  final DateTime? expire;

  int get used => upload + download;
  int get remaining => total > used ? total - used : 0;

  bool get hasUnlimitedTraffic => total == 0;
  bool get hasUnlimitedTime => expire == null;
}
