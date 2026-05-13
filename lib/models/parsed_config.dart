import 'package:input_vpn/models/proxy_type.dart';

/// Structured representation of a parsed VPN proxy URI.
///
/// All transport/TLS specifics are kept in `transport` so we don't tie the
/// model to any concrete VPN backend yet.
class ParsedConfig {
  const ParsedConfig({
    required this.type,
    required this.server,
    required this.port,
    required this.remark,
    this.uuid,
    this.password,
    this.method,
    this.network,
    this.security,
    this.sni,
    this.alpn,
    this.flow,
    this.publicKey,
    this.shortId,
    this.fingerprint,
    this.path,
    this.host,
    this.headerType,
    this.transport = const {},
    this.raw = '',
  });

  final ProxyType type;
  final String server;
  final int port;

  /// Human-readable name (from URI fragment or `ps` field for VMess).
  final String remark;

  /// User identifier:
  /// - VLESS/VMess: UUID
  final String? uuid;

  /// Auth password:
  /// - Trojan: password
  /// - Shadowsocks: password (after method decoding)
  /// - Hysteria2: auth string
  final String? password;

  /// Encryption method:
  /// - Shadowsocks: e.g. aes-128-gcm, chacha20-ietf-poly1305, 2022-blake3-aes-128-gcm
  /// - VMess: encryption alg
  final String? method;

  /// Transport network: tcp, ws, grpc, h2, quic, http.
  final String? network;

  /// Security layer: tls, reality, none.
  final String? security;

  /// TLS Server Name Indication.
  final String? sni;

  /// TLS ALPN list (comma-separated).
  final String? alpn;

  /// VLESS xtls flow control: xtls-rprx-vision, etc.
  final String? flow;

  /// REALITY public key.
  final String? publicKey;

  /// REALITY short id.
  final String? shortId;

  /// TLS client fingerprint (chrome, firefox, safari...).
  final String? fingerprint;

  /// Transport path (for ws/h2/grpc serviceName).
  final String? path;

  /// HTTP Host header or grpc authority.
  final String? host;

  /// VMess legacy header type: none, http.
  final String? headerType;

  /// Raw transport-specific parameters that didn't get a dedicated field.
  final Map<String, dynamic> transport;

  /// Original URI string for re-export / debugging.
  final String raw;

  ParsedConfig copyWith({String? remark}) => ParsedConfig(
    type: type,
    server: server,
    port: port,
    remark: remark ?? this.remark,
    uuid: uuid,
    password: password,
    method: method,
    network: network,
    security: security,
    sni: sni,
    alpn: alpn,
    flow: flow,
    publicKey: publicKey,
    shortId: shortId,
    fingerprint: fingerprint,
    path: path,
    host: host,
    headerType: headerType,
    transport: transport,
    raw: raw,
  );

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'server': server,
    'port': port,
    'remark': remark,
    if (uuid != null) 'uuid': uuid,
    if (password != null) 'password': password,
    if (method != null) 'method': method,
    if (network != null) 'network': network,
    if (security != null) 'security': security,
    if (sni != null) 'sni': sni,
    if (alpn != null) 'alpn': alpn,
    if (flow != null) 'flow': flow,
    if (publicKey != null) 'public_key': publicKey,
    if (shortId != null) 'short_id': shortId,
    if (fingerprint != null) 'fingerprint': fingerprint,
    if (path != null) 'path': path,
    if (host != null) 'host': host,
    if (headerType != null) 'header_type': headerType,
    if (transport.isNotEmpty) 'transport': transport,
    'raw': raw,
  };

  factory ParsedConfig.fromJson(Map<String, dynamic> json) => ParsedConfig(
    type: ProxyType.values.byName(json['type'] as String),
    server: json['server'] as String,
    port: json['port'] as int,
    remark: json['remark'] as String,
    uuid: json['uuid'] as String?,
    password: json['password'] as String?,
    method: json['method'] as String?,
    network: json['network'] as String?,
    security: json['security'] as String?,
    sni: json['sni'] as String?,
    alpn: json['alpn'] as String?,
    flow: json['flow'] as String?,
    publicKey: json['public_key'] as String?,
    shortId: json['short_id'] as String?,
    fingerprint: json['fingerprint'] as String?,
    path: json['path'] as String?,
    host: json['host'] as String?,
    headerType: json['header_type'] as String?,
    transport: (json['transport'] as Map<String, dynamic>?) ?? const {},
    raw: json['raw'] as String? ?? '',
  );

  @override
  String toString() =>
      '$type $remark ($server:$port, network=$network, security=$security)';
}

/// Wrapper for a parsing result so callers can distinguish a list of entries
/// (subscription) from a single entry (manual link) without losing failures.
class ParseResult {
  const ParseResult({required this.configs, this.failures = const []});

  final List<ParsedConfig> configs;

  /// Lines that failed to parse: (raw line, error message).
  final List<({String line, String error})> failures;

  bool get isEmpty => configs.isEmpty;
  bool get isNotEmpty => configs.isNotEmpty;
}
