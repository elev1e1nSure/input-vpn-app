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
}
