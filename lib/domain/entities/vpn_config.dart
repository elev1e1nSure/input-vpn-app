enum ConfigType { single, subscription }

class VpnConfig {
  const VpnConfig({
    required this.id,
    required this.name,
    required this.rawConfig,
    required this.type,
    required this.addedAt,
    this.subUrl,
    this.subUpload,
    this.subDownload,
    this.subTotal,
    this.subExpire,
  });

  final String id;
  final String name;
  final String rawConfig;
  final ConfigType type;
  final DateTime addedAt;
  final String? subUrl;
  final int? subUpload;
  final int? subDownload;
  final int? subTotal;
  final int? subExpire;

  bool get hasSubStats => subUpload != null || subDownload != null;
  int get subUsed => (subUpload ?? 0) + (subDownload ?? 0);
  int get subRemaining => subTotal != null ? subTotal! - subUsed : 0;
  bool get hasUnlimitedTraffic => subTotal == null || subTotal == 0;
}
