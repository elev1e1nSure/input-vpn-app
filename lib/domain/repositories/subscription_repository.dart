import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/parsed_config.dart';

class SubscriptionInfo {
  const SubscriptionInfo({
    this.upload,
    this.download,
    this.total,
    this.expire,
  });

  final int? upload;
  final int? download;
  final int? total;
  final DateTime? expire;
}

class SubscriptionResult {
  const SubscriptionResult({
    required this.configs,
    this.info,
    this.title,
    this.failures = const [],
  });

  final List<ParsedConfig> configs;
  final SubscriptionInfo? info;
  final String? title;
  final List<({String line, String error})> failures;

  bool get isEmpty => configs.isEmpty;
  bool get isNotEmpty => configs.isNotEmpty;
}

abstract class SubscriptionRepository {
  Result<SubscriptionResult> fetchSubscription(String url);
}
