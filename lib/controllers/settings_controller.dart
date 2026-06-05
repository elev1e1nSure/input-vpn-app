import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/models/dns_preset.dart';

/// Manages app settings: theme, locale, DNS, proxy port, startup behavior.
class SettingsController extends ChangeNotifier {
  SettingsController({required PrefsDataSource prefs}) : _prefs = prefs {
    _load();
  }

  final PrefsDataSource _prefs;

  // --- State ---
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.dark;
  bool _connectOnBoot = false;
  bool _autoLaunch = false;
  bool _minimizeToTray = false;
  String _customDns = 'Default';
  String _dnsPreset = 'cloudflare';
  String? _dnsCustomId;
  int _proxyPort = 11080;
  final List<CustomDnsProfile> _customDnsProfiles = [];

  // --- Getters ---
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get connectOnBoot => _connectOnBoot;
  bool get autoLaunch => _autoLaunch;
  bool get minimizeToTray => _minimizeToTray;
  String get customDns => _customDns;
  String get dnsPreset => _dnsPreset;
  String? get dnsCustomId => _dnsCustomId;
  int get proxyPort => _proxyPort;
  List<CustomDnsProfile> get customDnsProfiles =>
      List.unmodifiable(_customDnsProfiles);

  CustomDnsProfile? get selectedCustomDnsProfile {
    if (_dnsCustomId == null) return null;
    try {
      return _customDnsProfiles.firstWhere((p) => p.id == _dnsCustomId);
    } on StateError {
      return null;
    }
  }

  List<String> get currentDnsServers {
    final custom = selectedCustomDnsProfile;
    if (custom != null && custom.servers.isNotEmpty) {
      return custom.servers;
    }
    final preset = DnsPreset.byId(_dnsPreset);
    if (preset != null && preset.servers.isNotEmpty) {
      return preset.servers;
    }
    return const ['1.1.1.1', '8.8.8.8'];
  }

  // --- Setters ---
  void setLocale(String languageCode) {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    _prefs.setString('locale', languageCode);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _prefs.setBool('darkTheme', mode == ThemeMode.dark);
    notifyListeners();
  }

  void setConnectOnBoot(bool value) {
    if (_connectOnBoot == value) return;
    _connectOnBoot = value;
    _prefs.setBool('connectOnBoot', value);
    notifyListeners();
  }

  void setAutoLaunch(bool value) {
    if (_autoLaunch == value) return;
    _autoLaunch = value;
    _prefs.setBool('autoLaunch', value);
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    if (_minimizeToTray == value) return;
    _minimizeToTray = value;
    _prefs.setBool('minimizeToTray', value);
    notifyListeners();
  }

  void setCustomDns(String dns) {
    if (_customDns == dns) return;
    _customDns = dns;
    _prefs.setString('customDns', dns);
    notifyListeners();
  }

  void setDnsPreset(String preset) {
    if (_dnsPreset == preset && _dnsCustomId == null) return;
    _dnsPreset = preset;
    _prefs.setString('dnsPreset', preset);
    if (_dnsCustomId != null) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
    }
    notifyListeners();
  }

  void selectCustomDns(String profileId) {
    if (_dnsCustomId == profileId) return;
    _dnsCustomId = profileId;
    _prefs.setString('dnsCustomId', profileId);
    notifyListeners();
  }

  void setProxyPort(int port) {
    if (_proxyPort == port) return;
    _proxyPort = port;
    _prefs.setInt('proxyPort', port);
    notifyListeners();
  }

  void saveCustomDnsProfile(CustomDnsProfile profile) {
    final index = _customDnsProfiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _customDnsProfiles[index] = profile;
    } else {
      _customDnsProfiles.add(profile);
    }
    _persistCustomDnsProfiles();
    notifyListeners();
    if (_dnsCustomId == profile.id) {
      notifyListeners();
    }
  }

  void deleteCustomDnsProfile(String id) {
    final before = _customDnsProfiles.length;
    _customDnsProfiles.removeWhere((p) => p.id == id);
    if (before == _customDnsProfiles.length) return;
    _persistCustomDnsProfiles();
    if (_dnsCustomId == id) {
      _dnsCustomId = null;
      _prefs.remove('dnsCustomId');
      setDnsPreset(_dnsPreset);
      return;
    }
    notifyListeners();
  }

  // --- Persistence ---
  void _load() {
    _connectOnBoot = _prefs.getBool('connectOnBoot');
    _autoLaunch = _prefs.getBool('autoLaunch');
    _minimizeToTray = _prefs.getBool('minimizeToTray');
    _customDns = _prefs.getString('customDns') ?? 'Default';
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

  void _persistCustomDnsProfiles() {
    final jsonStr =
        jsonEncode(_customDnsProfiles.map((p) => p.toJson()).toList());
    _prefs.setJson('customDnsProfiles', jsonStr);
  }
}
