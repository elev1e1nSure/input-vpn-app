import 'package:flutter/material.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';

class SettingsState {
  final Locale locale;
  final ThemeMode themeMode;
  final bool connectOnBoot;
  final bool autoLaunch;
  final bool minimizeToTray;
  final String dnsPreset;
  final String? dnsCustomId;
  final int proxyPort;
  final List<CustomDnsProfile> customDnsProfiles;

  const SettingsState({
    this.locale = const Locale('en'),
    this.themeMode = ThemeMode.dark,
    this.connectOnBoot = false,
    this.autoLaunch = false,
    this.minimizeToTray = false,
    this.dnsPreset = 'cloudflare',
    this.dnsCustomId,
    this.proxyPort = 11080,
    this.customDnsProfiles = const [],
  });

  SettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
    bool? connectOnBoot,
    bool? autoLaunch,
    bool? minimizeToTray,
    String? dnsPreset,
    String? dnsCustomId,
    int? proxyPort,
    List<CustomDnsProfile>? customDnsProfiles,
  }) {
    return SettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      connectOnBoot: connectOnBoot ?? this.connectOnBoot,
      autoLaunch: autoLaunch ?? this.autoLaunch,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      dnsPreset: dnsPreset ?? this.dnsPreset,
      dnsCustomId: dnsCustomId ?? this.dnsCustomId,
      proxyPort: proxyPort ?? this.proxyPort,
      customDnsProfiles: customDnsProfiles ?? this.customDnsProfiles,
    );
  }
}
