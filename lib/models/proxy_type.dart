/// VPN proxy protocol types.
///
/// Protocols supported by the sing-box engine.
enum ProxyType {
  vless('VLESS'),
  vmess('VMess'),
  trojan('Trojan'),
  shadowsocks('Shadowsocks'),
  hysteria2('Hysteria2'),
  hysteria('Hysteria'),
  tuic('TUIC'),
  wireguard('WireGuard'),
  ssh('SSH'),
  unknown('Unknown');

  const ProxyType(this.label);

  final String label;

  /// Parse from a URI scheme such as `vless`, `vmess`, `ss`, `trojan`, `hy2`.
  static ProxyType fromScheme(String? scheme) {
    switch (scheme?.toLowerCase()) {
      case 'vless':
        return ProxyType.vless;
      case 'vmess':
        return ProxyType.vmess;
      case 'trojan':
        return ProxyType.trojan;
      case 'ss':
      case 'ssconf':
        return ProxyType.shadowsocks;
      case 'hy2':
      case 'hysteria2':
        return ProxyType.hysteria2;
      case 'hy':
      case 'hysteria':
        return ProxyType.hysteria;
      case 'tuic':
        return ProxyType.tuic;
      case 'wg':
      case 'wireguard':
        return ProxyType.wireguard;
      case 'ssh':
        return ProxyType.ssh;
      default:
        return ProxyType.unknown;
    }
  }
}
