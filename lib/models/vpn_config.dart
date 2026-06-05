import 'package:input_vpn/models/config_type.dart';

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

  factory VpnConfig.fromJson(Map<String, dynamic> json) => VpnConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        rawConfig: json['rawConfig'] as String,
        type: ConfigType.values.byName(json['type'] as String),
        addedAt: DateTime.parse(json['addedAt'] as String),
        subUrl: json['subUrl'] as String?,
        subUpload: json['subUpload'] as int?,
        subDownload: json['subDownload'] as int?,
        subTotal: json['subTotal'] as int?,
        subExpire: json['subExpire'] as int?,
      );

  final String id;

  final String name;

  final String rawConfig;

  final ConfigType type;

  final DateTime addedAt;

  final String? subUrl;

  // Subscription stats (bytes)
  final int? subUpload;
  final int? subDownload;
  final int? subTotal;
  // Unix timestamp
  final int? subExpire;

  bool get hasSubStats => subUpload != null || subDownload != null;
  int get subUsed => (subUpload ?? 0) + (subDownload ?? 0);
  int get subRemaining => subTotal != null ? subTotal! - subUsed : 0;
  bool get hasUnlimitedTraffic => subTotal == null || subTotal == 0;

  String get subUsedHuman => _bytesToHuman(subUsed);
  String get subTotalHuman =>
      hasUnlimitedTraffic ? '∞' : _bytesToHuman(subTotal!);
  String get subRemainingHuman =>
      hasUnlimitedTraffic ? '∞' : _bytesToHuman(subRemaining);

  static String _bytesToHuman(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rawConfig': rawConfig,
        'type': type.name,
        'addedAt': addedAt.toIso8601String(),
        if (subUrl != null) 'subUrl': subUrl,
        if (subUpload != null) 'subUpload': subUpload,
        if (subDownload != null) 'subDownload': subDownload,
        if (subTotal != null) 'subTotal': subTotal,
        if (subExpire != null) 'subExpire': subExpire,
      };
}
