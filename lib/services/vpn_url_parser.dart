import 'dart:convert';

import 'package:vpn/models/parsed_config.dart';
import 'package:vpn/models/proxy_type.dart';

/// Parses VPN proxy share-links (vless://, vmess://, ss://, trojan://, hy2://)
/// into a structured [ParsedConfig].
///
/// The parsing logic follows sing-box client conventions:
///   - VMess uses base64(JSON) body.
///   - VLESS/Trojan/Hysteria2 follow standard URI: scheme://user@host:port?params#remark
///   - Shadowsocks supports legacy base64 form and SIP002 form.
///
/// This is **pure Dart** — no native dependencies. It does **not** start a
/// tunnel; that requires a separate native backend.
class VpnUrlParser {
  /// Best-effort parse of a single share link. Returns null on failure.
  static ParsedConfig? tryParse(String link) {
    try {
      return parse(link);
    } catch (_) {
      return null;
    }
  }

  /// Strict parse: throws [FormatException] on failure.
  static ParsedConfig parse(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('empty link');
    }

    final schemeEnd = trimmed.indexOf('://');
    if (schemeEnd <= 0) {
      throw FormatException('no scheme in "$trimmed"');
    }
    final scheme = trimmed.substring(0, schemeEnd).toLowerCase();

    switch (scheme) {
      case 'vless':
        return _parseVless(trimmed);
      case 'vmess':
        return _parseVmess(trimmed);
      case 'trojan':
        return _parseTrojan(trimmed);
      case 'ss':
        return _parseShadowsocks(trimmed);
      case 'hy2':
      case 'hysteria2':
        return _parseHysteria2(trimmed);
      case 'tuic':
        return _parseTuic(trimmed);
      default:
        throw FormatException('unsupported scheme "$scheme"');
    }
  }

  // ---------------------------------------------------------------------------
  // Common URI parser used by VLESS, Trojan, and Hysteria2.
  // ---------------------------------------------------------------------------
  static ({String host, int port, String remark, Map<String, String> qp})
      _parseCommonUri(String link, String protocolName) {
    final uri = Uri.parse(link);
    final host = uri.host;
    final port = uri.port == 0 ? 443 : uri.port;
    if (host.isEmpty) throw FormatException('$protocolName: missing host');
    return (
      host: host,
      port: port,
      remark: _extractRemark(uri, fallback: host),
      qp: uri.queryParameters,
    );
  }

  // ---------------------------------------------------------------------------
  // VLESS
  // ---------------------------------------------------------------------------
  // vless://<uuid>@<host>:<port>?type=ws&security=tls&sni=...&path=...#<remark>
  static ParsedConfig _parseVless(String link) {
    final uuid = Uri.decodeComponent(Uri.parse(link).userInfo);
    if (uuid.isEmpty) throw const FormatException('vless: missing uuid');
    final c = _parseCommonUri(link, 'vless');
    final qp = c.qp;
    return ParsedConfig(
      type: ProxyType.vless,
      server: c.host,
      port: c.port,
      remark: c.remark,
      uuid: uuid,
      network: qp['type'] ?? 'tcp',
      security: qp['security'] ?? 'none',
      sni: qp['sni'] ?? qp['peer'],
      alpn: qp['alpn'],
      flow: qp['flow'],
      publicKey: qp['pbk'],
      shortId: qp['sid'],
      fingerprint: qp['fp'],
      path: qp['path'] ?? qp['serviceName'],
      host: qp['host'] ?? qp['authority'],
      transport: Map.of(qp),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // VMess — body is base64(JSON) per Quan/V2RayN convention
  // ---------------------------------------------------------------------------
  // vmess://<base64-json>
  static ParsedConfig _parseVmess(String link) {
    final body = link.substring('vmess://'.length);
    final jsonStr = _decodeBase64Permissive(body);
    Map<String, dynamic> obj;
    try {
      obj = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('vmess: not base64(JSON) body: $e');
    }

    final host = (obj['add'] ?? '').toString();
    final port = int.tryParse((obj['port'] ?? '').toString()) ?? 0;
    final uuid = (obj['id'] ?? '').toString();
    if (host.isEmpty || port == 0 || uuid.isEmpty) {
      throw FormatException('vmess: missing add/port/id in $obj');
    }
    return ParsedConfig(
      type: ProxyType.vmess,
      server: host,
      port: port,
      remark: (obj['ps'] ?? '').toString().isNotEmpty
          ? obj['ps'].toString()
          : host,
      uuid: uuid,
      method: (obj['scy'] ?? 'auto').toString(),
      network: (obj['net'] ?? 'tcp').toString(),
      security: (obj['tls'] ?? 'none').toString(),
      sni: (obj['sni'] ?? '').toString().isEmpty ? null : obj['sni'].toString(),
      alpn: (obj['alpn'] ?? '').toString().isEmpty ? null : obj['alpn'].toString(),
      fingerprint:
          (obj['fp'] ?? '').toString().isEmpty ? null : obj['fp'].toString(),
      path: (obj['path'] ?? '').toString().isEmpty ? null : obj['path'].toString(),
      host: (obj['host'] ?? '').toString().isEmpty ? null : obj['host'].toString(),
      headerType:
          (obj['type'] ?? '').toString().isEmpty ? null : obj['type'].toString(),
      transport: Map<String, dynamic>.from(obj),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Trojan
  // ---------------------------------------------------------------------------
  // trojan://<password>@<host>:<port>?sni=...&type=ws&path=...#<remark>
  static ParsedConfig _parseTrojan(String link) {
    final password = Uri.decodeComponent(Uri.parse(link).userInfo);
    if (password.isEmpty) throw const FormatException('trojan: missing password');
    final c = _parseCommonUri(link, 'trojan');
    final qp = c.qp;
    return ParsedConfig(
      type: ProxyType.trojan,
      server: c.host,
      port: c.port,
      remark: c.remark,
      password: password,
      network: qp['type'] ?? 'tcp',
      security: qp['security'] ?? 'tls',
      sni: qp['sni'] ?? qp['peer'],
      alpn: qp['alpn'],
      fingerprint: qp['fp'],
      path: qp['path'] ?? qp['serviceName'],
      host: qp['host'],
      transport: Map.of(qp),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Shadowsocks
  // ---------------------------------------------------------------------------
  // Two formats:
  //   1) ss://base64(method:password)@host:port#remark   (SIP002 base64 of userinfo)
  //   2) ss://base64(method:password@host:port)#remark   (legacy, full base64)
  //   3) ss://base64(method:password)@host:port?plugin=...#remark
  static ParsedConfig _parseShadowsocks(String link) {
    final hashIdx = link.indexOf('#');
    final core =
        hashIdx == -1 ? link.substring(5) : link.substring(5, hashIdx);
    final remark = hashIdx == -1
        ? ''
        : Uri.decodeComponent(link.substring(hashIdx + 1));

    String method = '';
    String password = '';
    String host = '';
    int port = 0;
    Map<String, String> qp = const {};

    if (core.contains('@')) {
      // SIP002 form: base64(method:password)@host:port?params
      final atIdx = core.indexOf('@');
      final userPart = core.substring(0, atIdx);
      final hostPart = core.substring(atIdx + 1);
      final mp = _decodeBase64Permissive(userPart);
      final colonIdx = mp.indexOf(':');
      if (colonIdx == -1) {
        throw FormatException('ss: malformed method:password "$mp"');
      }
      method = mp.substring(0, colonIdx);
      password = mp.substring(colonIdx + 1);

      final qIdx = hostPart.indexOf('?');
      String hp;
      if (qIdx == -1) {
        hp = hostPart;
      } else {
        hp = hostPart.substring(0, qIdx);
        qp = Uri.splitQueryString(hostPart.substring(qIdx + 1));
      }
      final lastColon = hp.lastIndexOf(':');
      if (lastColon == -1) {
        throw FormatException('ss: malformed host:port "$hp"');
      }
      host = hp.substring(0, lastColon);
      port = int.tryParse(hp.substring(lastColon + 1)) ?? 0;
    } else {
      // Legacy: ss://base64(method:password@host:port)
      final decoded = _decodeBase64Permissive(core);
      final atIdx = decoded.indexOf('@');
      if (atIdx == -1) {
        throw FormatException('ss: legacy form has no @ in "$decoded"');
      }
      final mp = decoded.substring(0, atIdx);
      final hp = decoded.substring(atIdx + 1);
      final colonIdx = mp.indexOf(':');
      final lastColon = hp.lastIndexOf(':');
      if (colonIdx == -1 || lastColon == -1) {
        throw FormatException('ss: legacy form malformed "$decoded"');
      }
      method = mp.substring(0, colonIdx);
      password = mp.substring(colonIdx + 1);
      host = hp.substring(0, lastColon);
      port = int.tryParse(hp.substring(lastColon + 1)) ?? 0;
    }

    if (host.isEmpty || port == 0) {
      throw const FormatException('ss: missing host or port');
    }

    return ParsedConfig(
      type: ProxyType.shadowsocks,
      server: host,
      port: port,
      remark: remark.isNotEmpty ? remark : host,
      method: method,
      password: password,
      transport: Map<String, dynamic>.from(qp),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // Hysteria2
  // ---------------------------------------------------------------------------
  // hy2://<auth>@<host>:<port>?sni=...&insecure=1#<remark>
  static ParsedConfig _parseHysteria2(String link) {
    final auth = Uri.decodeComponent(Uri.parse(link).userInfo);
    if (auth.isEmpty) throw const FormatException('hy2: missing auth');
    final c = _parseCommonUri(link, 'hy2');
    final qp = c.qp;
    return ParsedConfig(
      type: ProxyType.hysteria2,
      server: c.host,
      port: c.port,
      remark: c.remark,
      password: auth,
      network: 'udp',
      security: qp['insecure'] == '1' ? 'insecure' : 'tls',
      sni: qp['sni'] ?? qp['peer'],
      fingerprint: qp['fp'],
      transport: Map.of(qp),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // TUIC v5
  // ---------------------------------------------------------------------------
  // tuic://<uuid>:<password>@<host>:<port>?sni=...&congestion_control=bbr#<remark>
  static ParsedConfig _parseTuic(String link) {
    final uri = Uri.parse(link);
    final ui = Uri.decodeComponent(uri.userInfo);
    final sep = ui.indexOf(':');
    if (sep == -1) {
      throw const FormatException('tuic: malformed user info (uuid:password)');
    }
    final uuid = ui.substring(0, sep);
    final password = ui.substring(sep + 1);
    final host = uri.host;
    final port = uri.port == 0 ? 443 : uri.port;
    if (host.isEmpty || uuid.isEmpty) {
      throw const FormatException('tuic: missing host or uuid');
    }

    final qp = uri.queryParameters;
    return ParsedConfig(
      type: ProxyType.tuic,
      server: host,
      port: port,
      remark: _extractRemark(uri, fallback: host),
      uuid: uuid,
      password: password,
      security: 'tls',
      sni: qp['sni'],
      alpn: qp['alpn'],
      transport: Map.of(qp),
      raw: link,
    );
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------
  static String _extractRemark(Uri uri, {required String fallback}) {
    if (uri.fragment.isEmpty) return fallback;
    try {
      return Uri.decodeComponent(uri.fragment);
    } catch (_) {
      return uri.fragment;
    }
  }

  /// Decode base64 input that may be standard or URL-safe and may be missing
  /// padding.
  static String _decodeBase64Permissive(String input) {
    var s = input.replaceAll('-', '+').replaceAll('_', '/').replaceAll(
          RegExp(r'\s'),
          '',
        );
    while (s.length % 4 != 0) {
      s += '=';
    }
    final bytes = base64.decode(s);
    return utf8.decode(bytes, allowMalformed: true);
  }
}

/// Public helper to decode possibly base64-encoded subscription bodies.
///
/// Subscription endpoints typically return either:
///   - A base64 blob whose decoded contents is a newline-separated list of
///     proxy share links.
///   - Plain text with one share link per line.
String safeDecodeBase64(String input) {
  final trimmed = input.trim();
  // If text already looks like share-links, skip decoding.
  if (RegExp(r'^(vless|vmess|trojan|ss|hy2|hysteria2|tuic)://',
          caseSensitive: false)
      .hasMatch(trimmed)) {
    return trimmed;
  }
  try {
    var s = trimmed
        .replaceAll('-', '+')
        .replaceAll('_', '/')
        .replaceAll(RegExp(r'\s'), '');
    while (s.length % 4 != 0) {
      s += '=';
    }
    final bytes = base64.decode(s);
    return utf8.decode(bytes, allowMalformed: true);
  } catch (_) {
    return trimmed;
  }
}
