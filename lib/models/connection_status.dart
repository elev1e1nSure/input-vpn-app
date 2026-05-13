import 'package:input_vpn/models/connection_failure.dart';

/// Connection lifecycle status states.
sealed class ConnectionStatus {
  const ConnectionStatus();
  bool get isConnected => this is Connected;
  bool get isConnecting => this is Connecting;
  bool get isDisconnected => this is Disconnected;
}

class Disconnected extends ConnectionStatus {
  const Disconnected({this.failure});
  final ConnectionFailure? failure;
}

class Connecting extends ConnectionStatus {
  const Connecting();
}

class Connected extends ConnectionStatus {
  const Connected({required this.since});
  final DateTime since;
}
