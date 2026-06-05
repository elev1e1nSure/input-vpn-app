import 'parsed_config.dart';

class SignalQuality {
  const SignalQuality._();

  static int estimate(ParsedConfig config) {
    var score = 60;
    if (config.security == 'reality') {
      score += 30;
    } else if (config.security == 'tls') {
      score += 20;
    }
    if (config.network == 'grpc' || config.network == 'ws') {
      score += 5;
    }
    return score.clamp(10, 100);
  }
}
