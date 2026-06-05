import 'package:flutter/material.dart';

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
      icon: Icons.cloud,
      recommended: true,
    ),
    DnsPreset(
      id: 'google',
      labelEn: 'Google',
      labelRu: 'Google',
      servers: ['8.8.8.8', '8.8.4.4'],
      icon: Icons.search,
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
