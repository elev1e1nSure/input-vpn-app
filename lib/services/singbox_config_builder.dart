import 'dart:convert';

import 'package:vpn/models/parsed_config.dart';
import 'package:vpn/models/proxy_type.dart';

/// Builds a sing-box JSON configuration from a [ParsedConfig].
///
/// Output topology:
///   - `inbounds[0]` = TUN device (full-system VPN, auto_route=true)
///   - `outbounds[0]` = "proxy" (the actual VPN, derived from [ParsedConfig])
///   - `outbounds[1]` = "direct"
///   - `outbounds[2]` = "block"
///   - `dns` = remote DNS over the proxy, local DNS for the proxy server name
///   - `experimental.clash_api` = 127.0.0.1:9090 (for status/stats)
///
/// Reference: https://sing-box.sagernet.org/configuration/
class SingBoxConfigBuilder {
  const SingBoxConfigBuilder({
    this.clashApiPort = 9090,
    this.tunMtu = 9000,
    this.tunInterfaceName = 'InputVPNTun',
    this.remoteDnsServer = 'tls://1.1.1.1',
    this.directDnsServer = '8.8.8.8',
  });

  final int clashApiPort;
  final int tunMtu;
  final String tunInterfaceName;
  final String remoteDnsServer;
  final String directDnsServer;

  /// Build and return a pretty-printed JSON string ready to be passed to
  /// `sing-box run -c config.json`.
  ///
  /// If [logPath] is provided, sing-box will write its log to that file
  /// (otherwise the log goes to stdout, which is detached when we spawn the
  /// process via ShellExecuteEx).
  String build(ParsedConfig p, {String? logPath}) =>
      const JsonEncoder.withIndent('  ').convert(buildJson(p, logPath: logPath));

  Map<String, dynamic> buildJson(ParsedConfig p, {String? logPath}) {
    final outbound = _buildOutbound(p);

    return {
      'log': {
        'level': 'info',
        'timestamp': true,
        if (logPath != null) 'output': logPath,
      },
      'dns': {
        'servers': [
          {
            'tag': 'dns-remote',
            'address': remoteDnsServer,
            'address_resolver': 'dns-direct',
            'detour': 'proxy',
          },
          {
            'tag': 'dns-direct',
            'address': directDnsServer,
            'detour': 'direct',
          },
          {
            'tag': 'dns-block',
            'address': 'rcode://success',
          },
        ],
        'rules': [
          // Resolve the VPN server address itself directly (avoid loop).
          {
            'domain': [p.server],
            'server': 'dns-direct',
          },
        ],
        'final': 'dns-remote',
        'strategy': 'prefer_ipv4',
        'disable_cache': false,
      },
      'inbounds': [
        {
          'type': 'tun',
          'tag': 'tun-in',
          'interface_name': tunInterfaceName,
          'mtu': tunMtu,
          'inet4_address': '172.19.0.1/30',
          'inet6_address': 'fdfe:dcba:9876::1/126',
          'auto_route': true,
          'strict_route': true,
          'stack': 'mixed',
          'sniff': true,
          'sniff_override_destination': false,
        },
      ],
      'outbounds': [
        outbound,
        {'type': 'direct', 'tag': 'direct'},
        {'type': 'block', 'tag': 'block'},
        {'type': 'dns', 'tag': 'dns-out'},
      ],
      'route': {
        'rules': [
          {'protocol': 'dns', 'outbound': 'dns-out'},
          // Bypass private networks to avoid breaking LAN access.
          {
            'ip_cidr': [
              '127.0.0.0/8',
              '10.0.0.0/8',
              '172.16.0.0/12',
              '192.168.0.0/16',
              '169.254.0.0/16',
              '224.0.0.0/4',
            ],
            'outbound': 'direct',
          },
        ],
        'auto_detect_interface': true,
        'final': 'proxy',
      },
      'experimental': {
        'clash_api': {
          'external_controller': '127.0.0.1:$clashApiPort',
          'default_mode': 'rule',
        },
        'cache_file': {
          'enabled': true,
        },
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Per-protocol outbound builders
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _buildOutbound(ParsedConfig p) {
    switch (p.type) {
      case ProxyType.vless:
        return _vless(p);
      case ProxyType.vmess:
        return _vmess(p);
      case ProxyType.trojan:
        return _trojan(p);
      case ProxyType.shadowsocks:
        return _shadowsocks(p);
      case ProxyType.hysteria2:
        return _hysteria2(p);
      case ProxyType.hysteria:
        return _hysteria(p);
      case ProxyType.tuic:
        return _tuic(p);
      default:
        throw UnsupportedError(
            'Protocol ${p.type.label} is not yet supported by the sing-box bridge.');
    }
  }

  Map<String, dynamic> _vless(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'vless',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'uuid': p.uuid,
      if (p.flow != null && p.flow!.isNotEmpty) 'flow': p.flow,
    };
    _attachTls(out, p);
    _attachTransport(out, p);
    return out;
  }

  Map<String, dynamic> _vmess(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'vmess',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'uuid': p.uuid,
      'security': p.method ?? 'auto',
      'alter_id': 0,
    };
    _attachTls(out, p);
    _attachTransport(out, p);
    return out;
  }

  Map<String, dynamic> _trojan(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'trojan',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'password': p.password,
    };
    // Trojan defaults to TLS; if not specified, enable it.
    _attachTls(out, p, defaultEnabled: true);
    _attachTransport(out, p);
    return out;
  }

  Map<String, dynamic> _shadowsocks(ParsedConfig p) {
    return <String, dynamic>{
      'type': 'shadowsocks',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'method': p.method,
      'password': p.password,
    };
  }

  Map<String, dynamic> _hysteria2(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'hysteria2',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'password': p.password,
      'tls': {
        'enabled': true,
        if (p.sni != null) 'server_name': p.sni,
        if (p.alpn != null) 'alpn': p.alpn!.split(','),
        'insecure': p.transport['insecure'] == '1' || p.transport['insecure'] == 'true',
      },
    };
    return out;
  }

  Map<String, dynamic> _hysteria(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'hysteria',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'auth_str': p.password,
      'tls': {
        'enabled': true,
        if (p.sni != null) 'server_name': p.sni,
        if (p.alpn != null) 'alpn': p.alpn!.split(','),
      },
    };
    return out;
  }

  Map<String, dynamic> _tuic(ParsedConfig p) {
    final out = <String, dynamic>{
      'type': 'tuic',
      'tag': 'proxy',
      'server': p.server,
      'server_port': p.port,
      'uuid': p.uuid,
      'password': p.password,
      'congestion_control': p.transport['congestion_control'] ?? 'bbr',
      'tls': {
        'enabled': true,
        if (p.sni != null) 'server_name': p.sni,
        if (p.alpn != null) 'alpn': p.alpn!.split(','),
      },
    };
    return out;
  }

  // ---------------------------------------------------------------------------
  // TLS / Transport common builders
  // ---------------------------------------------------------------------------
  void _attachTls(
    Map<String, dynamic> out,
    ParsedConfig p, {
    bool defaultEnabled = false,
  }) {
    final hasTls = p.security == 'tls' ||
        p.security == 'reality' ||
        defaultEnabled;
    if (!hasTls) return;

    final tls = <String, dynamic>{
      'enabled': true,
      if (p.sni != null && p.sni!.isNotEmpty) 'server_name': p.sni,
      if (p.alpn != null && p.alpn!.isNotEmpty)
        'alpn': p.alpn!.split(','),
      'insecure': p.transport['allowInsecure'] == '1' ||
          p.transport['insecure'] == '1' ||
          p.transport['insecure'] == 'true',
    };
    if (p.fingerprint != null && p.fingerprint!.isNotEmpty) {
      tls['utls'] = {
        'enabled': true,
        'fingerprint': p.fingerprint,
      };
    }
    if (p.security == 'reality' &&
        p.publicKey != null &&
        p.publicKey!.isNotEmpty) {
      tls['reality'] = {
        'enabled': true,
        'public_key': p.publicKey,
        if (p.shortId != null) 'short_id': p.shortId,
      };
    }
    out['tls'] = tls;
  }

  void _attachTransport(Map<String, dynamic> out, ParsedConfig p) {
    final net = (p.network ?? 'tcp').toLowerCase();
    switch (net) {
      case 'tcp':
      case '':
        // Default; no transport block needed unless HTTP header type=http.
        if (p.headerType == 'http' && p.host != null) {
          out['transport'] = {
            'type': 'http',
            'host': p.host!.split(','),
            if (p.path != null) 'path': p.path,
          };
        }
        return;
      case 'ws':
        out['transport'] = {
          'type': 'ws',
          if (p.path != null) 'path': p.path,
          if (p.host != null)
            'headers': {'Host': p.host},
          if (p.transport['max-early-data'] != null)
            'max_early_data':
                int.tryParse(p.transport['max-early-data'].toString()) ?? 0,
        };
        return;
      case 'grpc':
        out['transport'] = {
          'type': 'grpc',
          if (p.path != null) 'service_name': p.path,
        };
        return;
      case 'h2':
      case 'http':
        out['transport'] = {
          'type': 'http',
          if (p.host != null) 'host': p.host!.split(','),
          if (p.path != null) 'path': p.path,
        };
        return;
      case 'quic':
        out['transport'] = {'type': 'quic'};
        return;
      default:
        return;
    }
  }
}
