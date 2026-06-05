/// Typed connection failure errors.
sealed class ConnectionFailure implements Exception {
  const ConnectionFailure(this.message);
  final String message;
  @override
  String toString() => '$runtimeType($message)';
}

class NoActiveConfig extends ConnectionFailure {
  const NoActiveConfig() : super('No active VPN configuration selected.');
}

class BackendNotImplemented extends ConnectionFailure {
  const BackendNotImplemented()
      : super(
          'Native VPN backend is not yet integrated. '
          'Connection is simulated for UI testing.',
        );
}

class UnexpectedFailure extends ConnectionFailure {
  const UnexpectedFailure(super.message);
}

class SingBoxStartException extends ConnectionFailure {
  const SingBoxStartException(super.message);
}
