import 'package:vpn/config_type.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class VpnConfig {
  const VpnConfig({
    required this.id,
    required this.name,
    required this.rawConfig,
    required this.type,
    required this.addedAt,
    this.subUrl,
  });

  final String id;

  final String name;

  final String rawConfig;

  final ConfigType type;

  final DateTime addedAt;

  final String? subUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'rawConfig': rawConfig,
    'type': type.name,
    'addedAt': addedAt.toIso8601String(),
    if (subUrl != null) 'subUrl': subUrl,
  };

  factory VpnConfig.fromJson(Map<String, dynamic> json) => VpnConfig(
    id: json['id'] as String,
    name: json['name'] as String,
    rawConfig: json['rawConfig'] as String,
    type: ConfigType.values.byName(json['type'] as String),
    addedAt: DateTime.parse(json['addedAt'] as String),
    subUrl: json['subUrl'] as String?,
  );
}
