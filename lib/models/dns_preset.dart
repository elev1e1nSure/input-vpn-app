import 'package:flutter/cupertino.dart';

/// A user-friendly DNS preset with display metadata and actual server IPs.
class DnsPreset {
  const DnsPreset({
    required this.id,
    required this.labelEn,
    required this.labelRu,
    required this.servers,
    required this.icon,
    this.recommended = false,
  });

  final String id;
  final String labelEn;
  final String labelRu;
  final List<String> servers;
  final IconData icon;
  final bool recommended;

  String label(bool isRu) => isRu ? labelRu : labelEn;

  static const presets = [
    DnsPreset(
      id: 'cloudflare',
      labelEn: 'Cloudflare',
      labelRu: 'Cloudflare',
      servers: ['1.1.1.1', '1.0.0.1'],
      icon: CupertinoIcons.cloud_fill,
      recommended: true,
    ),
    DnsPreset(
      id: 'google',
      labelEn: 'Google',
      labelRu: 'Google',
      servers: ['8.8.8.8', '8.8.4.4'],
      icon: CupertinoIcons.search,
    ),
    DnsPreset(
      id: 'adguard',
      labelEn: 'AdGuard',
      labelRu: 'AdGuard',
      servers: ['94.140.14.14', '94.140.15.15'],
      icon: CupertinoIcons.shield_fill,
    ),
    DnsPreset(
      id: 'system',
      labelEn: 'System',
      labelRu: 'Системный',
      servers: [],
      icon: CupertinoIcons.gear,
    ),
  ];

  static DnsPreset? byId(String id) {
    try {
      return presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return presets.first;
    }
  }
}
