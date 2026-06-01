import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/config_type.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';
import 'package:input_vpn/vpn_config.dart';
import 'package:input_vpn/vpn_server.dart';
import 'package:uuid/uuid.dart';

class ServerManager extends ChangeNotifier {
  ServerManager({required SubscriptionService subscriptionService})
      : _subs = subscriptionService;

  final SubscriptionService _subs;
  final List<VpnConfig> _configs = [];
  final List<VpnServer> _servers = [];
  VpnConfig? _selectedConfig;
  VpnServer? _selectedServer;

  List<VpnConfig> get configs => List.unmodifiable(_configs);
  List<VpnServer> get servers => List.unmodifiable(_servers);
  VpnConfig? get selectedConfig => _selectedConfig;
  VpnServer? get selectedServer => _selectedServer;

  bool get hasConfigs => _configs.isNotEmpty;
  bool get hasServers => _servers.isNotEmpty;

  Future<void> loadConfigs(List<VpnConfig> configs) async {
    _configs.clear();
    _configs.addAll(configs);
    _rebuildServers();
    notifyListeners();
  }

  Future<void> addConfig(String name, String rawConfig) async {
    final parsed = VpnUrlParser.tryParse(rawConfig);
    if (parsed == null) {
      throw const FormatException('Invalid VPN config');
    }

    final config = VpnConfig(
      id: const Uuid().v4(),
      name: name,
      rawConfig: rawConfig,
      type: _getConfigType(parsed),
      addedAt: DateTime.now(),
    );

    _configs.add(config);
    _rebuildServers();
    notifyListeners();
  }

  Future<void> addSubscription(String url) async {
    try {
      final configs = await _subs.fetch(url);
      final subConfig = VpnConfig(
        id: const Uuid().v4(),
        name: 'Subscription',
        rawConfig: url,
        type: ConfigType.subscription,
        addedAt: DateTime.now(),
        subUrl: url,
        subUpload: configs.fold(0, (sum, c) => sum + (c.subUpload ?? 0)),
        subDownload: configs.fold(0, (sum, c) => sum + (c.subDownload ?? 0)),
        subTotal: configs.isEmpty ? null : configs.first.subTotal,
        subExpire: configs.isEmpty ? null : configs.first.subExpire,
      );

      _configs.add(subConfig);
      _rebuildServers();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to add subscription: $e');
      rethrow;
    }
  }

  Future<void> removeConfig(String configId) async {
    _configs.removeWhere((c) => c.id == configId);
    if (_selectedConfig?.id == configId) {
      _selectedConfig = null;
      _selectedServer = null;
    }
    _rebuildServers();
    notifyListeners();
  }

  Future<void> updateConfig(String configId, String name, String rawConfig) async {
    final index = _configs.indexWhere((c) => c.id == configId);
    if (index == -1) return;

    final parsed = VpnUrlParser.tryParse(rawConfig);
    if (parsed == null) {
      throw const FormatException('Invalid VPN config');
    }

    _configs[index] = VpnConfig(
      id: configId,
      name: name,
      rawConfig: rawConfig,
      type: _getConfigType(parsed),
      addedAt: _configs[index].addedAt,
    );

    _rebuildServers();
    notifyListeners();
  }

  void selectConfig(VpnConfig? config) {
    _selectedConfig = config;
    _selectedServer = null;
    notifyListeners();
  }

  void selectServer(VpnServer? server) {
    _selectedServer = server;
    if (server != null) {
      final config = _configs.firstWhere(
        (c) => c.id == server.configId,
        orElse: () => _configs.first,
      );
      _selectedConfig = config;
    }
    notifyListeners();
  }

  List<VpnConfig> getSubscriptionConfigs() {
    return _configs.where((c) => c.type == ConfigType.subscription).toList();
  }

  Future<void> refreshSubscription(String configId) async {
    final config = _configs.firstWhere((c) => c.id == configId);
    if (config.subUrl == null) return;

    try {
      final configs = await _subs.fetch(config.subUrl!);
      _configs.removeWhere((c) => c.id == configId);

      final updatedConfig = VpnConfig(
        id: configId,
        name: config.name,
        rawConfig: config.rawConfig,
        type: ConfigType.subscription,
        addedAt: config.addedAt,
        subUrl: config.subUrl,
        subUpload: configs.fold(0, (sum, c) => sum + (c.subUpload ?? 0)),
        subDownload: configs.fold(0, (sum, c) => sum + (c.subDownload ?? 0)),
        subTotal: configs.isEmpty ? null : configs.first.subTotal,
        subExpire: configs.isEmpty ? null : configs.first.subExpire,
      );

      _configs.add(updatedConfig);
      _rebuildServers();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Failed to refresh subscription: $e');
      rethrow;
    }
  }

  ParsedConfig? getParsedConfig(VpnConfig config) {
    if (config.type == ConfigType.subscription) {
      return null;
    }
    return VpnUrlParser.tryParse(config.rawConfig);
  }

  List<ParsedConfig> getParsedSubscriptionConfigs(VpnConfig config) {
    if (config.type != ConfigType.subscription || config.subUrl == null) {
      return [];
    }
    final configs = _subs.getCachedConfigs(config.subUrl!);
    return configs;
  }

  void _rebuildServers() {
    _servers.clear();

    for (final config in _configs) {
      if (config.type == ConfigType.subscription) {
        final parsedConfigs = getParsedSubscriptionConfigs(config);
        for (final parsed in parsedConfigs) {
          _servers.add(_createServerFromParsed(parsed, config));
        }
      } else {
        final parsed = getParsedConfig(config);
        if (parsed != null) {
          _servers.add(_createServerFromParsed(parsed, config));
        }
      }
    }
  }

  VpnServer _createServerFromParsed(ParsedConfig parsed, VpnConfig config) {
    return VpnServer(
      id: const Uuid().v4(),
      name: parsed.remark.isNotEmpty ? parsed.remark : config.name,
      country: _extractCountry(parsed.remark),
      city: _extractCity(parsed.remark),
      flagCode: _extractFlagCode(parsed.remark),
      signalQuality: 100,
      rawConfig: parsed.toString(),
      configId: config.id,
    );
  }

  String _extractCountry(String remark) {
    final parts = remark.split('|');
    if (parts.length >= 2) return parts[0].trim();
    return 'Unknown';
  }

  String _extractCity(String remark) {
    final parts = remark.split('|');
    if (parts.length >= 3) return parts[1].trim();
    return '';
  }

  String _extractFlagCode(String remark) {
    final country = _extractCountry(remark);
    if (country.length == 2) return country.toUpperCase();
    return 'UN';
  }

  ConfigType _getConfigType(ParsedConfig parsed) {
    switch (parsed.type) {
      case ProxyType.vless:
        return ConfigType.vless;
      case ProxyType.vmess:
        return ConfigType.vmess;
      case ProxyType.shadowsocks:
        return ConfigType.shadowsocks;
      case ProxyType.trojan:
        return ConfigType.trojan;
      case ProxyType.hysteria2:
      case ProxyType.tuic:
        return ConfigType.vless;
    }
  }

  List<VpnConfig> exportConfigs() {
    return List.from(_configs);
  }
}
