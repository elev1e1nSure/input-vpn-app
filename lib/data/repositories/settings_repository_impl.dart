import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/domain/entities/dns_profile.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/models/dns_preset.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required PrefsDataSource prefs}) : _prefs = prefs;

  final PrefsDataSource _prefs;

  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;
  bool _connectOnBoot = false;
  bool _autoLaunch = false;
  bool _minimizeToTray = false;
  String _dnsPreset = 'cloudflare';
  String? _dnsCustomId;
  int _proxyPort = 11080;
  final List<CustomDnsProfile> _customDnsProfiles = [];

  @override
  Result<Locale> getLocale() => Result.ok(_locale);

  @override
  Result<ThemeMode> getThemeMode() => Result.ok(_themeMode);

  @override
  Result<bool> getConnectOnBoot() => Result.ok(_connectOnBoot);

  @override
  Result<bool> getAutoLaunch() => Result.ok(_autoLaunch);

  @override
  Result<bool> getMinimizeToTray() => Result.ok(_minimizeToTray);

  @override
  Result<String> getDnsPreset() => Result.ok(_dnsPreset);

  @override
  Result<String?> getDnsCustomId() => Result.ok(_dnsCustomId);

  @override
  Result<int> getProxyPort() => Result.ok(_proxyPort);

  @override
  Result<List<DnsProfile>> getCustomDnsProfiles() {
    return Result.ok(_customDnsProfiles
        .map((p) => DnsProfile(
              id: p.id,
              name: p.name,
              primary: p.servers.isNotEmpty ? p.servers.first : '',
              secondary: p.servers.length > 1 ? p.servers[1] : null,
            ))
        .toList());
  }

  @override
  Result<List<String>> getCurrentDnsServers() {
    final custom = getSelectedCustomDnsProfile();
    if (custom.isSuccess &&
        custom.value != null &&
        custom.value!.servers.isNotEmpty) {
      return Result.ok(custom.value!.servers);
    }
    final preset = DnsPreset.byId(_dnsPreset);
    if (preset != null && preset.servers.isNotEmpty) {
      return Result.ok(preset.servers);
    }
    return Result.ok(const ['1.1.1.1', '8.8.8.8']);
  }

  @override
  Result<DnsProfile?> getSelectedCustomDnsProfile() {
    if (_dnsCustomId == null) return Result.ok(null);
    try {
      final profile =
          _customDnsProfiles.firstWhere((p) => p.id == _dnsCustomId);
      return Result.ok(DnsProfile(
        id: profile.id,
        name: profile.name,
        primary: profile.servers.isNotEmpty ? profile.servers.first : '',
        secondary: profile.servers.length > 1 ? profile.servers[1] : null,
      ));
    } on StateError {
      return Result.ok(null);
    }
  }

  @override
  Result<void> setLocale(String languageCode) {
    if (_locale.languageCode == languageCode) return Result.ok(null);
    _locale = Locale(languageCode);
    _prefs.setString('locale', languageCode);
    return Result.ok(null);
  }

  @override
  Result<void> setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return Result.ok(null);
    _themeMode = mode;
    _prefs.setBool('darkTheme', mode == ThemeMode.dark);
    return Result.ok(null);
  }

  @override
  Result<void> setConnectOnBoot(bool value) {
    if (_connectOnBoot == value) return Result.ok(null);
    _connectOnBoot = value;
    _prefs.setBool('connectOnBoot', value);
    return Result.ok(null);
  }

  @override
  Result<void> setAutoLaunch(bool value) {
    if (_autoLaunch == value) return Result.ok(null);
    _autoLaunch = value;
    _prefs.setBool('autoLaunch', value);
    return Result.ok(null);
  }

  @override
  Result<void> setMinimizeToTray(bool value) {
    if (_minimizeToTray == value) return Result.ok(null);
    _minimizeToTray = value;
    _prefs.setBool('minimizeToTray', value);
    return Result.ok(null);
  }

  @override
  Result<void> setDnsPreset(String preset) {
    if (_dnsPreset == preset && _dnsCustomId == null) return Result.ok(null);
    _dnsPreset = preset;
    _prefs.setString('dnsPreset', preset);
    if (_dnsCustomId != null) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
    }
    return Result.ok(null);
  }

  @override
  Result<void> selectCustomDns(String profileId) {
    if (_dnsCustomId == profileId) return Result.ok(null);
    _dnsCustomId = profileId;
    _prefs.setString('dnsCustomId', profileId);
    return Result.ok(null);
  }

  @override
  Result<void> setProxyPort(int port) {
    if (_proxyPort == port) return Result.ok(null);
    _proxyPort = port;
    _prefs.setInt('proxyPort', port);
    return Result.ok(null);
  }

  @override
  Result<void> saveCustomDnsProfile(DnsProfile profile) {
    final customProfile = CustomDnsProfile(
      id: profile.id,
      name: profile.name,
      primary: profile.primary,
      secondary: profile.secondary,
    );
    final index = _customDnsProfiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _customDnsProfiles[index] = customProfile;
    } else {
      _customDnsProfiles.add(customProfile);
    }
    _persistCustomDnsProfiles();
    return Result.ok(null);
  }

  @override
  Result<void> deleteCustomDnsProfile(String id) {
    final before = _customDnsProfiles.length;
    _customDnsProfiles.removeWhere((p) => p.id == id);
    if (before == _customDnsProfiles.length) return Result.ok(null);
    _persistCustomDnsProfiles();
    if (_dnsCustomId == id) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
      setDnsPreset(_dnsPreset);
    }
    return Result.ok(null);
  }

  void _persistCustomDnsProfiles() {
    final jsonStr =
        jsonEncode(_customDnsProfiles.map((p) => p.toJson()).toList());
    _prefs.setJson('customDnsProfiles', jsonStr);
  }

  @override
  Result<void> load() {
    _connectOnBoot = _prefs.getBool('connectOnBoot');
    _autoLaunch = _prefs.getBool('autoLaunch');
    _minimizeToTray = _prefs.getBool('minimizeToTray');
    _dnsPreset = _prefs.getString('dnsPreset') ?? 'cloudflare';
    _proxyPort = _prefs.getInt('proxyPort', defaultValue: 11080);
    _dnsCustomId = _prefs.getString('dnsCustomId');
    final localeStr = _prefs.getString('locale') ?? 'en';
    _locale = Locale(localeStr);
    final darkTheme = _prefs.getBool('darkTheme', defaultValue: true);
    _themeMode = darkTheme ? ThemeMode.dark : ThemeMode.light;

    final customDnsJson = _prefs.getString('customDnsProfiles');
    if (customDnsJson != null && customDnsJson.isNotEmpty) {
      try {
        final list = jsonDecode(customDnsJson) as List<dynamic>;
        for (final item in list) {
          _customDnsProfiles.add(
            CustomDnsProfile.fromJson(item as Map<String, dynamic>),
          );
        }
      } on Exception catch (_) {
        // Malformed saved profiles are best-effort
      }
    }
    return Result.ok(null);
  }
}
