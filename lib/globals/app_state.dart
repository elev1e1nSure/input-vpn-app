import 'package:flutter/material.dart';
import 'package:vpn/globals/themes.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/vpn_server.dart';
import 'package:vpn/vpn_config.dart';
import 'package:vpn/config_type.dart';
import 'package:vpn/main.dart';
import 'package:provider/provider.dart';

@NowaGenerated()
class AppState extends ChangeNotifier {
  AppState() {
    _isPremium = sharedPrefs.getBool('isPremium') ?? true;
    _vpnProtocol = sharedPrefs.getString('vpnProtocol') ?? 'WireGuard';
    _killSwitch = sharedPrefs.getBool('killSwitch') ?? true;
    _connectOnBoot = sharedPrefs.getBool('connectOnBoot') ?? false;
    _customDns = sharedPrefs.getString('customDns') ?? 'Default';
  }

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = darkTheme;

  ThemeData get theme {
    return _theme;
  }

  bool _isConnected = false;

  bool get isConnected {
    return _isConnected;
  }

  bool _isConnecting = false;

  bool get isConnecting {
    return _isConnecting;
  }

  VpnServer? _selectedServer;

  VpnServer? get selectedServer {
    return _selectedServer;
  }

  List<VpnConfig> _userConfigs = [];

  List<VpnConfig> get userConfigs {
    return _userConfigs;
  }

  List<VpnServer> _userServers = [];

  List<VpnServer> get userServers {
    return _userServers;
  }

  int _ping = 0;

  int get ping {
    return _ping;
  }

  String _downloadSpeed = '0.0 KB/s';

  String get downloadSpeed {
    return _downloadSpeed;
  }

  String _uploadSpeed = '0.0 KB/s';

  String get uploadSpeed {
    return _uploadSpeed;
  }

  bool _isPremium = true;

  String _vpnProtocol = 'WireGuard';

  bool _killSwitch = true;

  bool _connectOnBoot = false;

  String _customDns = 'Default';

  bool get isPremium {
    return _isPremium;
  }

  String get vpnProtocol {
    return _vpnProtocol;
  }

  bool get killSwitch {
    return _killSwitch;
  }

  bool get connectOnBoot {
    return _connectOnBoot;
  }

  String get customDns {
    return _customDns;
  }

  void changeTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }

  void selectServer(VpnServer server) {
    _selectedServer = server;
    if (_isConnected) {
      _isConnected = false;
    }
    notifyListeners();
  }

  void addConfig(String name, String raw, ConfigType type) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newConfig = VpnConfig(
      id: id,
      name: name,
      rawConfig: raw,
      type: type,
      addedAt: DateTime.now(),
    );
    _userConfigs.add(newConfig);
    if (type != ConfigType.subscription) {
      final newServer = VpnServer(
        id: 's_${id}',
        name: name,
        country: 'Custom',
        city: 'Server',
        flagCode: 'UN',
        signalQuality: 100,
        rawConfig: raw,
        configId: id,
      );
      _userServers.add(newServer);
      if (_selectedServer == null) {
        _selectedServer = newServer;
      }
    } else {
      _userServers.addAll([
        VpnServer(
          id: 's_${id}_1',
          name: '${name} - NL',
          country: 'Netherlands',
          city: 'Amsterdam',
          flagCode: 'NL',
          signalQuality: 90,
          rawConfig: '...',
          configId: id,
        ),
        VpnServer(
          id: 's_${id}_2',
          name: '${name} - US',
          country: 'United States',
          city: 'Los Angeles',
          flagCode: 'US',
          signalQuality: 70,
          rawConfig: '...',
          configId: id,
        ),
        VpnServer(
          id: 's_${id}_3',
          name: '${name} - HK',
          country: 'Hong Kong',
          city: 'Hong Kong',
          flagCode: 'HK',
          signalQuality: 40,
          rawConfig: '...',
          configId: id,
        ),
      ]);
      if (_selectedServer == null) {
        _selectedServer = _userServers.first;
      }
    }
    notifyListeners();
  }

  void removeConfig(String configId) {
    _userConfigs.removeWhere((c) => c.id == configId);
    _userServers.removeWhere((s) => s.configId == configId);
    if (_selectedServer?.configId == configId) {
      _selectedServer = _userServers.isNotEmpty ? _userServers.first : null;
      _isConnected = false;
    }
    notifyListeners();
  }

  Future<void> toggleConnection() async {
    if (_selectedServer == null) {
      return;
    }
    if (_isConnected) {
      _isConnected = false;
      _ping = 0;
      _downloadSpeed = '0.0 KB/s';
      _uploadSpeed = '0.0 KB/s';
      notifyListeners();
      return;
    }
    if (_isConnecting) {
      return;
    }
    _isConnecting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _isConnecting = false;
    _isConnected = true;
    _ping = 100 - _selectedServer!.signalQuality + 15;
    _downloadSpeed =
        '${(45.5 * (_selectedServer!.signalQuality / 100)).toStringAsFixed(1)} MB/s';
    _uploadSpeed =
        '${(15.2 * (_selectedServer!.signalQuality / 100)).toStringAsFixed(1)} MB/s';
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    sharedPrefs.setBool('isPremium', _isPremium);
    notifyListeners();
  }

  void setVpnProtocol(String protocol) {
    _vpnProtocol = protocol;
    sharedPrefs.setString('vpnProtocol', protocol);
    notifyListeners();
  }

  void setKillSwitch(bool value) {
    _killSwitch = value;
    sharedPrefs.setBool('killSwitch', value);
    notifyListeners();
  }

  void setConnectOnBoot(bool value) {
    _connectOnBoot = value;
    sharedPrefs.setBool('connectOnBoot', value);
    notifyListeners();
  }

  void setCustomDns(String dns) {
    _customDns = dns;
    sharedPrefs.setString('customDns', dns);
    notifyListeners();
  }
}
