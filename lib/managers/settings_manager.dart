import 'package:flutter/foundation.dart';
import 'package:input_vpn/globals/shared_prefs.dart';
import 'package:input_vpn/models/dns_preset.dart';

class SettingsManager extends ChangeNotifier {
  bool _autoLaunch = false;
  bool _minimizeToTray = false;
  bool _connectOnBoot = false;
  bool _darkTheme = false;
  String _locale = 'en';
  String _dnsPreset = 'cloudflare';
  String _customDns = 'Default';
  int _proxyPort = 11080;
  bool _proxyMode = false;
  bool _serviceMode = false;

  bool get autoLaunch => _autoLaunch;
  bool get minimizeToTray => _minimizeToTray;
  bool get connectOnBoot => _connectOnBoot;
  bool get darkTheme => _darkTheme;
  String get locale => _locale;
  String get dnsPreset => _dnsPreset;
  String get customDns => _customDns;
  int get proxyPort => _proxyPort;
  bool get proxyMode => _proxyMode;
  bool get serviceMode => _serviceMode;

  Future<void> load() async {
    _autoLaunch = sharedPrefs.getBool('autoLaunch') ?? false;
    _minimizeToTray = sharedPrefs.getBool('minimizeToTray') ?? false;
    _connectOnBoot = sharedPrefs.getBool('connectOnBoot') ?? false;
    _darkTheme = sharedPrefs.getBool('darkTheme') ?? true;
    _locale = sharedPrefs.getString('locale') ?? 'en';
    _dnsPreset = sharedPrefs.getString('dnsPreset') ?? 'cloudflare';
    _customDns = sharedPrefs.getString('customDns') ?? 'Default';
    _proxyPort = sharedPrefs.getInt('proxyPort') ?? 11080;
    _proxyMode = sharedPrefs.getBool('proxyMode') ?? false;
    _serviceMode = sharedPrefs.getBool('serviceMode') ?? false;
  }

  Future<void> save() async {
    await sharedPrefs.setBool('autoLaunch', _autoLaunch);
    await sharedPrefs.setBool('minimizeToTray', _minimizeToTray);
    await sharedPrefs.setBool('connectOnBoot', _connectOnBoot);
    await sharedPrefs.setBool('darkTheme', _darkTheme);
    await sharedPrefs.setString('locale', _locale);
    await sharedPrefs.setString('dnsPreset', _dnsPreset);
    await sharedPrefs.setString('customDns', _customDns);
    await sharedPrefs.setInt('proxyPort', _proxyPort);
    await sharedPrefs.setBool('proxyMode', _proxyMode);
    await sharedPrefs.setBool('serviceMode', _serviceMode);
  }

  void setAutoLaunch(bool value) {
    _autoLaunch = value;
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    _minimizeToTray = value;
    notifyListeners();
  }

  void setConnectOnBoot(bool value) {
    _connectOnBoot = value;
    notifyListeners();
  }

  void setDarkTheme(bool value) {
    _darkTheme = value;
    notifyListeners();
  }

  void setLocale(String value) {
    _locale = value;
    notifyListeners();
  }

  void setDnsPreset(String value) {
    _dnsPreset = value;
    notifyListeners();
  }

  void setCustomDns(String value) {
    _customDns = value;
    notifyListeners();
  }

  void setProxyPort(int value) {
    _proxyPort = value;
    notifyListeners();
  }

  void setProxyMode(bool value) {
    _proxyMode = value;
    notifyListeners();
  }

  void setServiceMode(bool value) {
    _serviceMode = value;
    notifyListeners();
  }

  DnsPreset getDnsPreset() {
    return DnsPreset.values.firstWhere(
      (p) => p.id == _dnsPreset,
      orElse: () => DnsPreset.cloudflare,
    );
  }

  Future<void> reset() async {
    _autoLaunch = false;
    _minimizeToTray = false;
    _connectOnBoot = false;
    _darkTheme = true;
    _locale = 'en';
    _dnsPreset = 'cloudflare';
    _customDns = 'Default';
    _proxyPort = 11080;
    _proxyMode = false;
    _serviceMode = false;
    await save();
    notifyListeners();
  }
}
