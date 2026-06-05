import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/repositories/vpn_config_repository.dart';
import 'package:input_vpn/functions/extract_country_code.dart';
import 'package:input_vpn/models/config_type.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/vpn_config.dart';
import 'package:input_vpn/models/vpn_server.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_url_parser.dart';
import 'package:input_vpn/globals/shared_prefs.dart';

class ConfigRepositoryImpl implements VpnConfigRepository {
  ConfigRepositoryImpl({required SubscriptionService subscriptionService})
      : _subs = subscriptionService;

  final SubscriptionService _subs;

  final List<VpnConfig> _userConfigs = [];
  final List<VpnServer> _userServers = [];
  final Map<String, ParsedConfig> _parsedByServerId = {};
  VpnServer? _selectedServer;

  @override
  Result<List<VpnConfig>> getUserConfigs() => Result.ok(_userConfigs);

  @override
  Result<List<VpnServer>> getUserServers() => Result.ok(_userServers);

  @override
  Result<VpnServer?> getSelectedServer() => Result.ok(_selectedServer);

  @override
  Result<ParsedConfig?> getParsedConfig(String serverId) =>
      Result.ok(_parsedByServerId[serverId]);

  @override
  Result<void> addConfig(String name, String raw, String type) {
    final trimmed = raw.trim();
    final isUrl =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (type == 'subscription' || isUrl) {
      _addSubscription(name, trimmed);
    } else {
      _addSingleLink(name, trimmed, type);
    }
    return Result.ok(null);
  }

  void _addSingleLink(String name, String link, String type) {
    final parsed = VpnUrlParser.tryParse(link);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _userConfigs.add(VpnConfig(
      id: id,
      name: name,
      rawConfig: link,
      type: _parseConfigType(type),
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
    } else {
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
    saveState();
  }

  void _addSubscription(String name, String url) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _userConfigs.add(VpnConfig(
      id: id,
      name: name,
      rawConfig: url,
      type: ConfigType.subscription,
      addedAt: DateTime.now(),
      subUrl: url,
    ));

    try {
      _subs.fetch(url).then((result) {
        if (result.isEmpty) return;

        final displayTitle =
            (name.isEmpty ? (result.title ?? 'Subscription') : name);

        final info = result.info;
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
      }).catchError((Object e) {
        debugPrint('Failed to load subscription "$name": $e');
      });
    } finally {
      saveState();
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

  @override
  Result<void> removeConfig(String configId) {
    _userConfigs.removeWhere((c) => c.id == configId);
    final removed = _userServers.where((s) => s.configId == configId).toList();
    _userServers.removeWhere((s) => s.configId == configId);
    for (final s in removed) {
      _parsedByServerId.remove(s.id);
    }
    if (_selectedServer?.configId == configId) {
      _selectedServer = _userServers.isNotEmpty ? _userServers.first : null;
    }
    saveState();
    return Result.ok(null);
  }

  @override
  Result<void> updateConfig(
      String configId, String newName, String newRawConfig) {
    final configIndex = _userConfigs.indexWhere((c) => c.id == configId);
    if (configIndex == -1) return Result.ok(null);

    final oldConfig = _userConfigs[configIndex];
    _userConfigs[configIndex] = VpnConfig(
      id: oldConfig.id,
      name: newName,
      rawConfig: newRawConfig,
      type: oldConfig.type,
      addedAt: oldConfig.addedAt,
      subUrl: oldConfig.subUrl,
    );

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

    saveState();
    return Result.ok(null);
  }

  @override
  Result<void> selectServer(VpnServer server) {
    _selectedServer = server;
    saveState();
    return Result.ok(null);
  }

  @override
  Result<void> refreshSubscriptionStats(String configId) {
    final configIndex = _userConfigs.indexWhere((c) => c.id == configId);
    if (configIndex == -1) return Result.ok(null);

    final config = _userConfigs[configIndex];
    if (config.subUrl == null) return Result.ok(null);

    _subs.fetch(config.subUrl!).then((result) {
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
        saveState();
      }
    }).catchError((Object e) {
      debugPrint('Failed to refresh subscription stats: $e');
    });
    return Result.ok(null);
  }

  @override
  Result<void> saveState() {
    try {
      final configsJson =
          jsonEncode(_userConfigs.map((c) => c.toJson()).toList());
      sharedPrefs.setString('userConfigs', configsJson);

      final serversJson =
          jsonEncode(_userServers.map((s) => s.toJson()).toList());
      sharedPrefs.setString('userServers', serversJson);

      sharedPrefs.setString('selectedServerId', _selectedServer?.id ?? '');

      final parsedJson = jsonEncode(
        _parsedByServerId.map((k, v) => MapEntry(k, v.toJson())),
      );
      sharedPrefs.setString('parsedByServerId', parsedJson);
    } catch (e) {
      debugPrint('Failed to save persisted state: $e');
    }
    return Result.ok(null);
  }

  @override
  Result<void> loadState() {
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
    } catch (e) {
      debugPrint('Failed to load persisted state: $e');
    }
    return Result.ok(null);
  }

  ConfigType _parseConfigType(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return ConfigType.subscription;
      case 'vless':
        return ConfigType.vless;
      case 'vmess':
        return ConfigType.vmess;
      case 'shadowsocks':
      case 'ss':
        return ConfigType.shadowsocks;
      case 'trojan':
        return ConfigType.trojan;
      default:
        return ConfigType.vless;
    }
  }
}
