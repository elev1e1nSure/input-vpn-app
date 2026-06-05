enum ProxyType {
  vless,
  vmess,
  ss,
  trojan,
  hy2,
  tuic,
}

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
  final String remark;
  final String? uuid;
  final String? password;
  final String? method;
  final String? network;
  final String? security;
  final String? sni;
  final String? alpn;
  final String? flow;
  final String? publicKey;
  final String? shortId;
  final String? fingerprint;
  final String? path;
  final String? host;
  final String? headerType;
  final Map<String, dynamic> transport;
  final String raw;
}
