import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vpn/globals/themes.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/functions/extract_country_code.dart';
import 'package:vpn/models/connection_status.dart';
import 'package:vpn/models/parsed_config.dart';
import 'package:vpn/models/vpn_stats.dart';
import 'package:vpn/services/singbox_vpn_service.dart';
import 'package:vpn/services/subscription_service.dart';
import 'package:vpn/services/vpn_service.dart';
import 'package:vpn/services/vpn_url_parser.dart';
import 'package:vpn/services/windows_startup_manager.dart';
import 'package:vpn/vpn_server.dart';
import 'package:vpn/vpn_config.dart';
import 'package:vpn/config_type.dart';
import 'package:provider/provider.dart';
import 'package:vpn/globals/shared_prefs.dart';

/// Choose the real backend on Windows, mock everywhere else.
///
/// Defaults to Full TUN VPN mode on Windows. A "Proxy mode"
/// toggle lets users run SOCKS-only (no UAC) instead of full TUN.
VpnService _defaultVpnBackend() {
  if (!kIsWeb && Platform.isWindows && SingBoxVpnService.isSupported) {
    // Default to FULL VPN (proxyMode=false) for production use.
    final proxy = sharedPrefs.getBool('proxyMode') ?? false;
    return SingBoxVpnService(proxyMode: proxy);
  }
  return MockVpnService();
}

@NowaGenerated()
class AppState extends ChangeNotifier {
  AppState({VpnService? vpnService, SubscriptionService? subscriptionService})
      : _vpn = vpnService ?? _defaultVpnBackend(),
        _subs = subscriptionService ?? SubscriptionService() {
    _connectOnBoot = sharedPrefs.getBool('connectOnBoot') ?? false;
    _autoLaunch = sharedPrefs.getBool('autoLaunch') ?? false;
    _customDns = sharedPrefs.getString('customDns') ?? 'Default';
    _dnsPreset = sharedPrefs.getString('dnsPreset') ?? 'cloudflare';
    _proxyPort = sharedPrefs.getInt('proxyPort') ?? 11080;
    _locale = Locale(sharedPrefs.getString('locale') ?? 'en');

    _statusSub = _vpn.watchStatus().listen(_onStatus);
    _statsSub = _vpn.watchStats().listen(_onStats);

    // Auto-connect on launch if enabled and a server is available.
    if (_connectOnBoot && _selectedServer != null) {
      _autoConnectTimer = Timer(const Duration(seconds: 1), () {
        if (!_isConnected && !_isConnecting) {
          toggleConnection();
        }
      });
    }
  }

  final VpnService _vpn;
  final SubscriptionService _subs;
  StreamSubscription<ConnectionStatus>? _statusSub;
  StreamSubscription<VpnStats>? _statsSub;
  Timer? _autoConnectTimer;
  Timer? _errorTimer;

  /// Parsed VPN configuration per server.id, populated by [addConfig].
  final Map<String, ParsedConfig> _parsedByServerId = {};

  String? _lastError;
  String? get lastError => _lastError;

  void clearError() {
    _errorTimer?.cancel();
    _errorTimer = null;
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  void _scheduleErrorClear() {
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 4), clearError);
  }

  /// Whether the Windows backend is running in SOCKS-proxy mode (no
  /// TUN device, no UAC). Returns false on non-Windows or non-singbox backends.
  bool get isProxyMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.proxyMode : false;
  }

  /// Toggle between SOCKS proxy mode and full TUN VPN mode.
  /// Will disconnect first if currently connected.
  Future<void> setProxyMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    await vpn.disconnect();
    vpn.setProxyMode(enabled);
    await sharedPrefs.setBool('proxyMode', enabled);
    notifyListeners();
  }

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(String languageCode) {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    sharedPrefs.setString('locale', languageCode);
    notifyListeners();
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

  final List<VpnConfig> _userConfigs = [];

  List<VpnConfig> get userConfigs {
    return _userConfigs;
  }

  final List<VpnServer> _userServers = [];

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

  bool _connectOnBoot = false;
  bool _autoLaunch = false;

  String _customDns = 'Default';
  String _dnsPreset = 'cloudflare';
  int _proxyPort = 11080;

  bool get connectOnBoot {
    return _connectOnBoot;
  }

  bool get autoLaunch {
    return _autoLaunch;
  }

  String get customDns {
    return _customDns;
  }

  String get dnsPreset {
    return _dnsPreset;
  }

  int get proxyPort {
    return _proxyPort;
  }

  void changeTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }

  void selectServer(VpnServer server) {
    _selectedServer = server;
    if (_isConnected) {
      _vpn.disconnect();
    }
    notifyListeners();
  }

  /// Add a config from raw input.
  ///
  /// - If [type] is `subscription` OR `raw` looks like an HTTP(S) URL: treats
  ///   it as a subscription, downloads, decodes (base64 fallback), parses each
  ///   line as vless://, vmess://, ss://, trojan://, hy2://, tuic:// and
  ///   creates one [VpnServer] per parsed entry.
  /// - Otherwise treats [raw] as a single share-link.
  void addConfig(String name, String raw, ConfigType type) {
    final trimmed = raw.trim();
    final isUrl =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (type == ConfigType.subscription || isUrl) {
      _addSubscription(name, trimmed);
      return;
    }
    _addSingleLink(name, trimmed, type);
  }

  void _addSingleLink(String name, String link, ConfigType type) {
    final parsed = VpnUrlParser.tryParse(link);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _userConfigs.add(VpnConfig(
      id: id,
      name: name,
      rawConfig: link,
      type: type,
      addedAt: DateTime.now(),
    ));
    final serverId = 's_$id';
    if (parsed != null) {
      final server = VpnServer(
        id: serverId,
        name: parsed.remark.isNotEmpty ? parsed.remark : name,
        country: parsed.server,
        city: '${parsed.server}:${parsed.port}',
        flagCode: extractCountryCode(parsed.remark),
        signalQuality: _estimateSignal(parsed),
        rawConfig: link,
        configId: id,
      );
      _userServers.add(server);
      _parsedByServerId[serverId] = parsed;
      _selectedServer ??= server;
      _lastError = null;
    } else {
      _lastError = 'Failed to parse "$name". Saved as raw config.';
      _scheduleErrorClear();
      _userServers.add(VpnServer(
        id: serverId,
        name: name,
        country: 'Unknown',
        city: '—',
        flagCode: 'UN',
        signalQuality: 0,
        rawConfig: link,
        configId: id,
      ));
    }
    notifyListeners();
  }

  Future<void> _addSubscription(String name, String url) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _userConfigs.add(VpnConfig(
      id: id,
      name: name,
      rawConfig: url,
      type: ConfigType.subscription,
      addedAt: DateTime.now(),
      subUrl: url,
    ));
    notifyListeners();
    try {
      final result = await _subs.fetch(url);
      if (result.isEmpty) {
        _lastError = result.failures.isEmpty
            ? 'Subscription "$name" contained no usable entries.'
            : 'Subscription "$name": ${result.failures.length} entries failed to parse.';
        _scheduleErrorClear();
        notifyListeners();
        return;
      }
      final displayTitle =
          (name.isEmpty ? (result.title ?? 'Subscription') : name);
      for (var i = 0; i < result.configs.length; i++) {
        final p = result.configs[i];
        final serverId = 's_${id}_$i';
        _userServers.add(VpnServer(
          id: serverId,
          name: p.remark.isNotEmpty ? p.remark : '$displayTitle ${i + 1}',
          country: p.server,
          city: '${p.server}:${p.port}',
          flagCode: extractCountryCode(p.remark),
          signalQuality: _estimateSignal(p),
          rawConfig: p.raw,
          configId: id,
        ));
        _parsedByServerId[serverId] = p;
      }
      _selectedServer ??= _userServers.isNotEmpty ? _userServers.first : null;
      _lastError = null;
    } catch (e) {
      _lastError = 'Failed to load subscription "$name": $e';
      _scheduleErrorClear();
    } finally {
      notifyListeners();
    }
  }

  int _estimateSignal(ParsedConfig p) {
    var score = 60;
    if (p.security == 'reality') {
      score += 30;
    } else if (p.security == 'tls') {
      score += 20;
    }
    if (p.network == 'grpc' || p.network == 'ws') score += 5;
    return score.clamp(10, 100);
  }

  void removeConfig(String configId) {
    _userConfigs.removeWhere((c) => c.id == configId);
    final removed = _userServers.where((s) => s.configId == configId).toList();
    _userServers.removeWhere((s) => s.configId == configId);
    for (final s in removed) {
      _parsedByServerId.remove(s.id);
    }
    if (_selectedServer?.configId == configId) {
      _selectedServer = _userServers.isNotEmpty ? _userServers.first : null;
      _vpn.disconnect();
    }
    notifyListeners();
  }

  Future<void> toggleConnection() async {
    final server = _selectedServer;
    if (server == null) return;
    if (_isConnected) {
      await _vpn.disconnect();
      return;
    }
    if (_isConnecting) return;
    final parsed = _parsedByServerId[server.id];
    if (parsed == null) {
      _lastError = 'Selected server has no parsed VPN configuration.';
      _scheduleErrorClear();
      notifyListeners();
      return;
    }
    await _vpn.connect(parsed);
  }

  void _onStatus(ConnectionStatus status) {
    switch (status) {
      case Connecting():
        _isConnecting = true;
        _isConnected = false;
      case Connected():
        _isConnecting = false;
        _isConnected = true;
      case Disconnected(failure: final f):
        _isConnecting = false;
        _isConnected = false;
        if (f != null) {
          _lastError = f.message;
          _scheduleErrorClear();
        }
        _ping = 0;
        _downloadSpeed = '0.0 KB/s';
        _uploadSpeed = '0.0 KB/s';
    }
    notifyListeners();
  }

  void _onStats(VpnStats stats) {
    _ping = stats.pingMs;
    _downloadSpeed = stats.downloadHuman;
    _uploadSpeed = stats.uploadHuman;
    notifyListeners();
  }

  void _persistBool(String key, bool Function() getter, void Function(bool) fieldSetter, bool value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setBool(key, value);
    notifyListeners();
  }

  void _persistString(String key, String Function() getter, void Function(String) fieldSetter, String value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setString(key, value);
    notifyListeners();
  }

  void _persistInt(String key, int Function() getter, void Function(int) fieldSetter, int value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setInt(key, value);
    notifyListeners();
  }

  void setConnectOnBoot(bool value) =>
      _persistBool('connectOnBoot', () => _connectOnBoot, (v) => _connectOnBoot = v, value);

  void setAutoLaunch(bool value) {
    if (_autoLaunch == value) return;
    _autoLaunch = value;
    sharedPrefs.setBool('autoLaunch', value);
    if (value) {
      WindowsStartupManager.enable(Platform.resolvedExecutable);
    } else {
      WindowsStartupManager.disable();
    }
    notifyListeners();
  }

  void setCustomDns(String dns) =>
      _persistString('customDns', () => _customDns, (v) => _customDns = v, dns);

  void setDnsPreset(String preset) =>
      _persistString('dnsPreset', () => _dnsPreset, (v) => _dnsPreset = v, preset);

  void setProxyPort(int port) =>
      _persistInt('proxyPort', () => _proxyPort, (v) => _proxyPort = v, port);

  @override
  void dispose() {
    _errorTimer?.cancel();
    _autoConnectTimer?.cancel();
    _statusSub?.cancel();
    _statsSub?.cancel();
    _vpn.dispose();
    super.dispose();
  }
}
