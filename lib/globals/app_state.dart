import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:input_vpn/globals/themes.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:input_vpn/functions/extract_country_code.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/models/dns_preset.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/singbox_vpn_service.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_service.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';
import 'package:input_vpn/services/tray_manager.dart';
import 'package:input_vpn/services/windows_startup_manager.dart';
import 'package:input_vpn/services/ip_service.dart';
import 'package:input_vpn/vpn_server.dart';
import 'package:input_vpn/vpn_config.dart';
import 'package:input_vpn/config_type.dart';
import 'package:provider/provider.dart';
import 'package:input_vpn/globals/shared_prefs.dart';

/// Choose the real backend on Windows, mock everywhere else.
///
/// Defaults to Full TUN VPN mode on Windows. A "Proxy mode"
/// toggle lets users run SOCKS-only (no UAC) instead of full TUN.
///
/// Android: returns [MockVpnService] for now. The real Android backend
/// (`VpnService` + sing-box core) is wired in step 2.
VpnService _defaultVpnBackend() {
  if (!kIsWeb && Platform.isWindows && SingBoxVpnService.isSupported) {
    // Default to FULL VPN (proxyMode=false) for production use.
    final proxy = sharedPrefs.getBool('proxyMode') ?? false;
    final service = sharedPrefs.getBool('serviceMode') ?? false;
    return SingBoxVpnService(proxyMode: proxy, serviceMode: service);
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
    _minimizeToTray = sharedPrefs.getBool('minimizeToTray') ?? false;
    _customDns = sharedPrefs.getString('customDns') ?? 'Default';
    _dnsPreset = sharedPrefs.getString('dnsPreset') ?? 'cloudflare';
    _proxyPort = sharedPrefs.getInt('proxyPort') ?? 11080;
    _locale = Locale(sharedPrefs.getString('locale') ?? 'en');

    _dnsCustomId = sharedPrefs.getString('dnsCustomId');
    _loadPersistedState();

    _statusSub = _vpn.watchStatus().listen(_onStatus);

    _applyDnsSelection();

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

  /// Live connection status stream — use with StreamBuilder for session timer.
  Stream<ConnectionStatus> get statusStream => _vpn.watchStatus();

  /// Whether the VPN service is in an auto-reconnect cycle after a crash.
  bool get isReconnecting {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.isReconnecting : false;
  }

  /// Current reconnect attempt number (1-based, 0 when not reconnecting).
  int get reconnectAttempt {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.reconnectAttempt : 0;
  }

  /// Whether sing-box launches as a Windows Service (no UAC per connection).
  bool get isServiceMode {
    final vpn = _vpn;
    return vpn is SingBoxVpnService ? vpn.serviceMode : false;
  }

  /// Enable / disable Windows Service mode. Disconnects first if connected.
  Future<void> setServiceMode(bool enabled) async {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    if (_isConnected) await vpn.disconnect();
    vpn.setServiceMode(enabled);
    await sharedPrefs.setBool('serviceMode', enabled);
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

  bool _isDisconnecting = false;

  bool get isDisconnecting => _isDisconnecting;

  bool _isConnecting = false;

  bool get isConnecting {
    return _isConnecting;
  }

  VpnServer? _selectedServer;

  VpnServer? get selectedServer {
    return _selectedServer;
  }

  String? get selectedServerAddress {
    final server = _selectedServer;
    if (server == null) return null;

    final parsedAddress = _parsedByServerId[server.id]?.server.trim();
    if (parsedAddress != null && parsedAddress.isNotEmpty) {
      return parsedAddress;
    }

    final country = server.country.trim();
    if (country.isNotEmpty && country != 'Unknown' && country != '—') {
      return country;
    }

    final city = server.city.trim();
    if (city.isEmpty) return null;
    final separatorIndex = city.indexOf(':');
    if (separatorIndex >= 0) {
      final beforeColon = city.substring(0, separatorIndex).trim();
      if (beforeColon.isNotEmpty) {
        return beforeColon;
      }
    }
    return city;
  }

  final List<VpnConfig> _userConfigs = [];

  List<VpnConfig> get userConfigs {
    return _userConfigs;
  }

  final List<VpnServer> _userServers = [];

  List<VpnServer> get userServers {
    return _userServers;
  }

  String? _publicIp;

  String? get publicIp => _publicIp;

  String? _countryCode;

  String? get countryCode => _countryCode;

  Future<void> refreshPublicIp() async {
    _publicIp = await IpService.fetchPublicIp();
    _countryCode = await IpService.fetchCountryCode();
    debugPrint('AppState: publicIp=$_publicIp, countryCode=$_countryCode');
    notifyListeners();
  }

  bool _connectOnBoot = false;
  bool _autoLaunch = false;
  bool _minimizeToTray = false;

  String _customDns = 'Default';
  String _dnsPreset = 'cloudflare';
  String? _dnsCustomId;
  int _proxyPort = 11080;
  final List<CustomDnsProfile> _customDnsProfiles = [];

  bool get connectOnBoot {
    return _connectOnBoot;
  }

  bool get autoLaunch {
    return _autoLaunch;
  }

  bool get minimizeToTray {
    return _minimizeToTray;
  }

  String get customDns {
    return _customDns;
  }

  String get dnsPreset {
    return _dnsPreset;
  }

  String? get dnsCustomId => _dnsCustomId;

  List<CustomDnsProfile> get customDnsProfiles =>
      List.unmodifiable(_customDnsProfiles);

  CustomDnsProfile? get selectedCustomDnsProfile {
    if (_dnsCustomId == null) return null;
    try {
      return _customDnsProfiles.firstWhere((p) => p.id == _dnsCustomId);
    } catch (_) {
      return null;
    }
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
    _savePersistedState().ignore();
    if (_isConnected) {
      _vpn.disconnect();
    }
    refreshPublicIp();
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
        flagCode: extractCountryCode(name),
        signalQuality: 0,
        rawConfig: link,
        configId: id,
      ));
    }
    _savePersistedState().ignore();
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

      // Get subscription stats
      final info = result.info;
      debugPrint(
          'Subscription stats: upload=${info?.upload}, download=${info?.download}, total=${info?.total}, expire=${info?.expire}');
      final configIndex = _userConfigs.indexWhere((c) => c.id == id);
      if (configIndex != -1 && info != null) {
        _userConfigs[configIndex] = VpnConfig(
          id: id,
          name: displayTitle,
          rawConfig: url,
          type: ConfigType.subscription,
          addedAt: DateTime.now(),
          subUrl: url,
          subUpload: info.upload,
          subDownload: info.download,
          subTotal: info.total,
          subExpire: info.expire != null
              ? info.expire!.millisecondsSinceEpoch ~/ 1000
              : null,
        );
      }

      for (var i = 0; i < result.configs.length; i++) {
        final p = result.configs[i];
        final serverId = 's_${id}_$i';
        debugPrint(
            'Subscription server $i: name=${p.remark}, server=${p.server}, port=${p.port}');
        _userServers.add(VpnServer(
          id: serverId,
          name: p.remark.isNotEmpty ? p.remark : '$displayTitle ${i + 1}',
          country: p.server.isNotEmpty ? p.server : displayTitle,
          city: p.server.isNotEmpty ? '${p.server}:${p.port}' : displayTitle,
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
      _savePersistedState().ignore();
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
    _savePersistedState().ignore();
    notifyListeners();
  }

  /// Update a config's name and raw config.
  void updateConfig(String configId, String newName, String newRawConfig) {
    final configIndex = _userConfigs.indexWhere((c) => c.id == configId);
    if (configIndex == -1) return;

    final oldConfig = _userConfigs[configIndex];
    _userConfigs[configIndex] = VpnConfig(
      id: oldConfig.id,
      name: newName,
      rawConfig: newRawConfig,
      type: oldConfig.type,
      addedAt: oldConfig.addedAt,
      subUrl: oldConfig.subUrl,
    );

    // Re-parse the config and update servers
    final parsed = VpnUrlParser.tryParse(newRawConfig);
    final serverIndices = _userServers
        .asMap()
        .entries
        .where((e) => e.value.configId == configId)
        .map((e) => e.key)
        .toList();

    for (final serverIndex in serverIndices) {
      final oldServer = _userServers[serverIndex];
      if (parsed != null) {
        _userServers[serverIndex] = VpnServer(
          id: oldServer.id,
          name: newName.isNotEmpty
              ? newName
              : (parsed.remark.isNotEmpty ? parsed.remark : newName),
          country: parsed.server,
          city: '${parsed.server}:${parsed.port}',
          flagCode: extractCountryCode(parsed.remark),
          signalQuality: _estimateSignal(parsed),
          rawConfig: newRawConfig,
          configId: configId,
        );
        _parsedByServerId[oldServer.id] = parsed;
      } else {
        _userServers[serverIndex] = VpnServer(
          id: oldServer.id,
          name: newName,
          country: 'Unknown',
          city: '—',
          flagCode: extractCountryCode(newName),
          signalQuality: 0,
          rawConfig: newRawConfig,
          configId: configId,
        );
      }
      if (_selectedServer?.id == oldServer.id) {
        _selectedServer = _userServers[serverIndex];
      }
    }

    _savePersistedState().ignore();
    notifyListeners();
  }

  /// Refresh subscription stats (upload/download/expire) from the server.
  Future<void> refreshSubscriptionStats(String configId) async {
    final configIndex = _userConfigs.indexWhere((c) => c.id == configId);
    if (configIndex == -1) return;

    final config = _userConfigs[configIndex];
    if (config.subUrl == null) return;

    try {
      final result = await _subs.fetch(config.subUrl!);
      final info = result.info;
      if (info != null) {
        _userConfigs[configIndex] = VpnConfig(
          id: config.id,
          name: config.name,
          rawConfig: config.rawConfig,
          type: config.type,
          addedAt: config.addedAt,
          subUrl: config.subUrl,
          subUpload: info.upload,
          subDownload: info.download,
          subTotal: info.total,
          subExpire: info.expire != null
              ? info.expire!.millisecondsSinceEpoch ~/ 1000
              : null,
        );
        _savePersistedState().ignore();
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - stats are best-effort
      debugPrint('Failed to refresh subscription stats: $e');
    }
  }

  Future<void> toggleConnection() async {
    final server = _selectedServer;
    if (server == null) return;
    if (_isConnected) {
      _isDisconnecting = true;
      notifyListeners();
      await _vpn.disconnect();
      _isDisconnecting = false;
      notifyListeners();
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
        TrayManager.updateTooltip('Connecting...');
        AppLogger.info(
          'Connecting to ${_selectedServer?.name ?? 'unknown server'}',
        );
      case Connected():
        _isConnecting = false;
        _isConnected = true;
        TrayManager.updateTooltip('Connected');
        AppLogger.info(
          'Connected to ${_selectedServer?.name ?? 'unknown server'}'
          ' (${_selectedServer?.city ?? ''})',
        );
        // Задержка 2 сек для установления туннеля
        Future.delayed(const Duration(seconds: 2), () => refreshPublicIp());
      case Disconnected(failure: final f):
        _isConnecting = false;
        _isDisconnecting = false;
        _isConnected = false;
        if (f != null) {
          _lastError = f.message;
          _scheduleErrorClear();
          AppLogger.error('Disconnected with error: ${f.message}');
        } else {
          AppLogger.info('Disconnected');
        }
        TrayManager.updateTooltip('Disconnected');
        // Задержка 1 сек для восстановления сети
        Future.delayed(const Duration(seconds: 1), () => refreshPublicIp());
    }
    notifyListeners();
  }

  void _persistBool(String key, bool Function() getter,
      void Function(bool) fieldSetter, bool value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setBool(key, value);
    notifyListeners();
  }

  void _persistString(String key, String Function() getter,
      void Function(String) fieldSetter, String value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setString(key, value);
    notifyListeners();
  }

  void _persistInt(String key, int Function() getter,
      void Function(int) fieldSetter, int value) {
    if (getter() == value) return;
    fieldSetter(value);
    sharedPrefs.setInt(key, value);
    notifyListeners();
  }

  void setConnectOnBoot(bool value) => _persistBool(
      'connectOnBoot', () => _connectOnBoot, (v) => _connectOnBoot = v, value);

  void setAutoLaunch(bool value) {
    if (_autoLaunch == value) return;
    _autoLaunch = value;
    sharedPrefs.setBool('autoLaunch', value);
    // Auto-launch is currently a Windows-only feature (HKCU registry).
    // Other platforms (Android, etc.) ignore the toggle until a native
    // implementation is added.
    if (Platform.isWindows) {
      if (value) {
        WindowsStartupManager.enable(Platform.resolvedExecutable);
      } else {
        WindowsStartupManager.disable();
      }
    }
    notifyListeners();
  }

  void setMinimizeToTray(bool value) {
    if (_minimizeToTray == value) return;
    _minimizeToTray = value;
    sharedPrefs.setBool('minimizeToTray', value);
    notifyListeners();
  }

  void setCustomDns(String dns) =>
      _persistString('customDns', () => _customDns, (v) => _customDns = v, dns);

  void setDnsPreset(String preset) {
    if (_dnsPreset == preset && _dnsCustomId == null) return;
    _dnsPreset = preset;
    sharedPrefs.setString('dnsPreset', preset);
    if (_dnsCustomId != null) {
      _dnsCustomId = null;
      sharedPrefs.remove('dnsCustomId');
    }
    notifyListeners();
    _applyDnsSelection();
  }

  void selectCustomDns(String profileId) {
    if (_dnsCustomId == profileId) return;
    _dnsCustomId = profileId;
    sharedPrefs.setString('dnsCustomId', profileId);
    notifyListeners();
    _applyDnsSelection();
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
      _applyDnsSelection();
    }
  }

  void deleteCustomDnsProfile(String id) {
    final before = _customDnsProfiles.length;
    _customDnsProfiles.removeWhere((p) => p.id == id);
    if (before == _customDnsProfiles.length) {
      return;
    }
    _persistCustomDnsProfiles();
    if (_dnsCustomId == id) {
      _dnsCustomId = null;
      sharedPrefs.remove('dnsCustomId');
      setDnsPreset(_dnsPreset);
      return;
    }
    notifyListeners();
  }

  void setProxyPort(int port) =>
      _persistInt('proxyPort', () => _proxyPort, (v) => _proxyPort = v, port);

  void _loadPersistedState() {
    try {
      final configsJson = sharedPrefs.getString('userConfigs');
      if (configsJson != null && configsJson.isNotEmpty) {
        final list = jsonDecode(configsJson) as List<dynamic>;
        for (final item in list) {
          final config = VpnConfig.fromJson(item as Map<String, dynamic>);
          _userConfigs.add(config);
        }
      }

      final serversJson = sharedPrefs.getString('userServers');
      if (serversJson != null && serversJson.isNotEmpty) {
        final list = jsonDecode(serversJson) as List<dynamic>;
        for (final item in list) {
          final server = VpnServer.fromJson(item as Map<String, dynamic>);
          _userServers.add(server);
        }
      }

      final selectedId = sharedPrefs.getString('selectedServerId');
      if (selectedId != null && selectedId.isNotEmpty) {
        _selectedServer = _userServers.cast<VpnServer?>().firstWhere(
              (s) => s?.id == selectedId,
              orElse: () => null,
            );
      }

      final parsedJson = sharedPrefs.getString('parsedByServerId');
      if (parsedJson != null && parsedJson.isNotEmpty) {
        final map = jsonDecode(parsedJson) as Map<String, dynamic>;
        for (final entry in map.entries) {
          _parsedByServerId[entry.key] =
              ParsedConfig.fromJson(entry.value as Map<String, dynamic>);
        }
      }

      final customDnsJson = sharedPrefs.getString('customDnsProfiles');
      if (customDnsJson != null && customDnsJson.isNotEmpty) {
        final list = jsonDecode(customDnsJson) as List<dynamic>;
        for (final item in list) {
          _customDnsProfiles
              .add(CustomDnsProfile.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('Failed to load persisted state: $e');
    }
  }

  Future<void> _savePersistedState() async {
    try {
      // Offload heavy JSON encoding to a microtask so it doesn't block animations
      final configsJson = await Future(
          () => jsonEncode(_userConfigs.map((c) => c.toJson()).toList()));
      await sharedPrefs.setString('userConfigs', configsJson);

      final serversJson = await Future(
          () => jsonEncode(_userServers.map((s) => s.toJson()).toList()));
      await sharedPrefs.setString('userServers', serversJson);

      await sharedPrefs.setString(
          'selectedServerId', _selectedServer?.id ?? '');

      final parsedJson = await Future(() => jsonEncode(
            _parsedByServerId.map((k, v) => MapEntry(k, v.toJson())),
          ));
      await sharedPrefs.setString('parsedByServerId', parsedJson);

      final customDnsJson = await Future(() => jsonEncode(
            _customDnsProfiles.map((p) => p.toJson()).toList(),
          ));
      await sharedPrefs.setString('customDnsProfiles', customDnsJson);
    } catch (e) {
      debugPrint('Failed to save persisted state: $e');
    }
  }

  void _persistCustomDnsProfiles() {
    final jsonStr =
        jsonEncode(_customDnsProfiles.map((p) => p.toJson()).toList());
    sharedPrefs.setString('customDnsProfiles', jsonStr);
  }

  void _applyDnsSelection() {
    final vpn = _vpn;
    if (vpn is! SingBoxVpnService) return;
    final servers = _currentDnsServers();
    final remote =
        servers.isNotEmpty ? 'tls://${servers.first}' : 'tls://1.1.1.1';
    final direct = servers.length > 1 ? servers[1] : '8.8.8.8';
    vpn.setDnsServers(remoteDns: remote, directDns: direct);
  }

  List<String> _currentDnsServers() {
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

  Map<String, dynamic> buildAnonymizedSettingsSnapshot() {
    final subscriptionCount =
        _userConfigs.where((c) => c.type == ConfigType.subscription).length;
    return {
      'preferences': {
        'connectOnBoot': _connectOnBoot,
        'autoLaunch': _autoLaunch,
        'minimizeToTray': _minimizeToTray,
        'proxyMode': isProxyMode,
        'theme': _theme.brightness == Brightness.dark ? 'dark' : 'light',
        'language': _locale.languageCode,
        'dns': {
          'preset': _dnsPreset,
          'customSelected': _dnsCustomId != null,
          'customProfiles': _customDnsProfiles.length,
        },
      },
      'counts': {
        'servers': _userServers.length,
        'configs': _userConfigs.length,
        'subscriptions': subscriptionCount,
        'customDnsProfiles': _customDnsProfiles.length,
      },
    };
  }

  Future<void> importAnonymizedSettings(Map<String, dynamic> data) async {
    final prefs = data['preferences'];
    if (prefs is Map<String, dynamic>) {
      final connect = prefs['connectOnBoot'];
      if (connect is bool) setConnectOnBoot(connect);

      final autoLaunch = prefs['autoLaunch'];
      if (autoLaunch is bool) setAutoLaunch(autoLaunch);

      final minimize = prefs['minimizeToTray'];
      if (minimize is bool) setMinimizeToTray(minimize);

      final proxy = prefs['proxyMode'];
      if (proxy is bool) {
        await setProxyMode(proxy);
      }

      final theme = prefs['theme'];
      if (theme == 'dark') {
        changeTheme(darkTheme);
      } else if (theme == 'light') {
        changeTheme(lightTheme);
      }

      final language = prefs['language'];
      if (language is String) {
        setLocale(language);
      }

      final dns = prefs['dns'];
      if (dns is Map<String, dynamic>) {
        final preset = dns['preset'];
        final customSelected = dns['customSelected'] == true;
        if (!customSelected && preset is String) {
          setDnsPreset(preset);
        }
      }
    }
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _autoConnectTimer?.cancel();
    _statusSub?.cancel();
    // Disconnect VPN to ensure TUN adapter cleanup on app exit
    if (_isConnected) {
      _vpn.disconnect().ignore();
    }
    _vpn.dispose();
    super.dispose();
  }
}
