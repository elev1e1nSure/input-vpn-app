import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/models/dns_preset.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';

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
  Locale get locale => _locale;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  bool get connectOnBoot => _connectOnBoot;

  @override
  bool get autoLaunch => _autoLaunch;

  @override
  bool get minimizeToTray => _minimizeToTray;

  @override
  String get dnsPreset => _dnsPreset;

  @override
  String? get dnsCustomId => _dnsCustomId;

  @override
  int get proxyPort => _proxyPort;

  @override
  List<CustomDnsProfile> get customDnsProfiles =>
      List.unmodifiable(_customDnsProfiles);

  @override
  List<String> getCurrentDnsServers() {
    final custom = getSelectedCustomDnsProfile();
    if (custom != null && custom.servers.isNotEmpty) {
      return custom.servers;
    }
    final preset = DnsPreset.byId(_dnsPreset);
    if (preset != null && preset.servers.isNotEmpty) {
      return preset.servers;
    }
    return const ['1.1.1.1', '8.8.8.8'];
  }

  @override
  CustomDnsProfile? getSelectedCustomDnsProfile() {
    if (_dnsCustomId == null) return null;
    try {
      return _customDnsProfiles.firstWhere((p) => p.id == _dnsCustomId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<void> setLocale(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    _prefs.setString('locale', languageCode);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs.setBool('darkTheme', mode == ThemeMode.dark);
  }

  @override
  Future<void> setConnectOnBoot(bool value) async {
    if (_connectOnBoot == value) return;
    _connectOnBoot = value;
    _prefs.setBool('connectOnBoot', value);
  }

  @override
  Future<void> setAutoLaunch(bool value) async {
    if (_autoLaunch == value) return;
    _autoLaunch = value;
    _prefs.setBool('autoLaunch', value);
  }

  @override
  Future<void> setMinimizeToTray(bool value) async {
    if (_minimizeToTray == value) return;
    _minimizeToTray = value;
    _prefs.setBool('minimizeToTray', value);
  }

  @override
  Future<void> setDnsPreset(String preset) async {
    if (_dnsPreset == preset && _dnsCustomId == null) return;
    _dnsPreset = preset;
    _prefs.setString('dnsPreset', preset);
    if (_dnsCustomId != null) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
    }
  }

  @override
  Future<void> selectCustomDns(String profileId) async {
    if (_dnsCustomId == profileId) return;
    _dnsCustomId = profileId;
    _prefs.setString('dnsCustomId', profileId);
  }

  @override
  Future<void> setProxyPort(int port) async {
    if (_proxyPort == port) return;
    _proxyPort = port;
    _prefs.setInt('proxyPort', port);
  }

  @override
  Future<void> saveCustomDnsProfile(CustomDnsProfile profile) async {
    final index = _customDnsProfiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _customDnsProfiles[index] = profile;
    } else {
      _customDnsProfiles.add(profile);
    }
    _persistCustomDnsProfiles();
  }

  @override
  Future<void> deleteCustomDnsProfile(String id) async {
    final before = _customDnsProfiles.length;
    _customDnsProfiles.removeWhere((p) => p.id == id);
    if (before == _customDnsProfiles.length) return;
    _persistCustomDnsProfiles();
    if (_dnsCustomId == id) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
      await setDnsPreset(_dnsPreset);
    }
  }

  void _persistCustomDnsProfiles() {
    final jsonStr =
        jsonEncode(_customDnsProfiles.map((p) => p.toJson()).toList());
    _prefs.setJson('customDnsProfiles', jsonStr);
  }

  @override
  Future<void> load() async {
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
  }
}
