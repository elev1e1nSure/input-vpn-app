import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:input_vpn/globals/shared_prefs.dart';
import 'package:input_vpn/vpn_config.dart';

class PersistenceManager {
  static const String _configsKey = 'vpn_configs';
  static const String _selectedConfigIdKey = 'selected_config_id';
  static const String _selectedServerIdKey = 'selected_server_id';

  Future<void> saveConfigs(List<VpnConfig> configs) async {
    final json = jsonEncode(configs.map((c) => c.toJson()).toList());
    await sharedPrefs.setString(_configsKey, json);
  }

  Future<List<VpnConfig>> loadConfigs() async {
    final json = sharedPrefs.getString(_configsKey);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((j) => VpnConfig.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Failed to load configs: $e');
      return [];
    }
  }

  Future<void> saveSelectedConfig(String? configId) async {
    if (configId == null) {
      await sharedPrefs.remove(_selectedConfigIdKey);
    } else {
      await sharedPrefs.setString(_selectedConfigIdKey, configId);
    }
  }

  Future<String?> loadSelectedConfigId() async {
    return sharedPrefs.getString(_selectedConfigIdKey);
  }

  Future<void> saveSelectedServer(String? serverId) async {
    if (serverId == null) {
      await sharedPrefs.remove(_selectedServerIdKey);
    } else {
      await sharedPrefs.setString(_selectedServerIdKey, serverId);
    }
  }

  Future<String?> loadSelectedServerId() async {
    return sharedPrefs.getString(_selectedServerIdKey);
  }

  Future<void> clear() async {
    await sharedPrefs.remove(_configsKey);
    await sharedPrefs.remove(_selectedConfigIdKey);
    await sharedPrefs.remove(_selectedServerIdKey);
  }
}
