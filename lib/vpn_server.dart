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

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'city': city,
    'flagCode': flagCode,
    'signalQuality': signalQuality,
    'rawConfig': rawConfig,
    'configId': configId,
  };

  factory VpnServer.fromJson(Map<String, dynamic> json) => VpnServer(
    id: json['id'] as String,
    name: json['name'] as String,
    country: json['country'] as String,
    city: json['city'] as String,
    flagCode: json['flagCode'] as String,
    signalQuality: json['signalQuality'] as int,
    rawConfig: json['rawConfig'] as String,
    configId: json['configId'] as String,
  );
}
