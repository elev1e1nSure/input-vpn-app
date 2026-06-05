/// An explicitly-typed result of an operation that may fail.
///
/// Use [Result.ok] for success and [Result.err] for failure.
/// Prefer pattern matching (Dart 3) or [when]/[map] over manual `is` checks.
sealed class Result<T> {
  const Result._();

  /// Create a success result.
  const factory Result.ok(T value) = Success<T>;

  /// Create a failure result with an error message.
  const factory Result.err(String message, {Object? cause}) =
      UnexpectedFailure<T>;

  /// Convenience wrapper around an async function.
  static Future<Result<T>> guard<T>(Future<T> Function() fn) async {
    try {
      return Result.ok(await fn());
    } on Exception catch (e) {
      return Result.err(e.toString(), cause: e);
    }
  }

  /// `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// `true` if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Get the value or throw if failure.
  T get value => switch (this) {
        Success(:final value) => value,
        Failure() => throw StateError('Called value on a failure result'),
      };

  /// Get the error message or `null` if success.
  String? get error => switch (this) {
        Failure(:final message) => message,
        Success() => null,
      };

  /// Transform value if success, pass through failure.
  Result<R> map<R>(R Function(T value) fn) {
    return switch (this) {
      Success(:final value) => Result.ok(fn(value)),
      Failure(:final message, :final cause) =>
        Result.err(message, cause: cause),
    };
  }

  /// Execute [onSuccess] or [onFailure] and return the produced value.
  R when<R>({
    required R Function(T value) onSuccess,
    required R Function(String message, Object? cause) onFailure,
  }) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final message, :final cause) => onFailure(message, cause),
    };
  }

  /// Return the value or a fallback.
  T getOrElse(T fallback) => isSuccess ? value : fallback;
}

final class Success<T> extends Result<T> {
  const Success(this.value) : super._();
  final T value;
}

sealed class Failure<T> extends Result<T> {
  const Failure(this.message, {this.cause}) : super._();
  final String message;
  final Object? cause;
}

final class UnexpectedFailure<T> extends Failure<T> {
  const UnexpectedFailure(super.message, {super.cause});
}

final class ParseFailure<T> extends Failure<T> {
  const ParseFailure(super.message, {super.cause});
}

final class NetworkFailure<T> extends Failure<T> {
  const NetworkFailure(super.message, {super.cause});
}

final class VpnFailure<T> extends Failure<T> {
  const VpnFailure(super.message, {super.cause});
}
