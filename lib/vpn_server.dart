import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class VpnServer {
  const VpnServer({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.flagCode,
    required this.signalQuality,
    required this.rawConfig,
    required this.configId,
  });

  final String id;

  final String name;

  final String country;

  final String city;

  final String flagCode;

  final int signalQuality;

  final String rawConfig;

  final String configId;
}
