import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/core/result.dart';

void main() {
  group('Result', () {
    test('Success holds value', () {
      const result = Result<int>.ok(42);
      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.value, 42);
      expect(result.error, null);
    });

    test('Failure holds message', () {
      const result = Result<int>.err('boom');
      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.error, 'boom');
    });

    test('map transforms success', () {
      const result = Result<int>.ok(2);
      final mapped = result.map((v) => v * 3);
      expect(mapped.value, 6);
    });

    test('map passes through failure', () {
      const result = Result<int>.err('fail');
      final mapped = result.map((v) => v * 3);
      expect(mapped.isFailure, true);
      expect(mapped.error, 'fail');
    });

    test('when returns correct branch', () {
      const ok = Result<int>.ok(1);
      const err = Result<int>.err('e');
      expect(ok.when(onSuccess: (v) => v, onFailure: (_, __) => -1), 1);
      expect(err.when(onSuccess: (v) => v, onFailure: (_, __) => -1), -1);
    });

    test('getOrElse returns value or fallback', () {
      expect(const Result<int>.ok(5).getOrElse(0), 5);
      expect(const Result<int>.err('x').getOrElse(0), 0);
    });

    test('guard returns ok on success', () async {
      final result = await Result.guard(() async => 10);
      expect(result.isSuccess, true);
      expect(result.value, 10);
    });

    test('guard returns err on exception', () async {
      final result = await Result.guard<int>(() async => throw Exception('oops'));
      expect(result.isFailure, true);
      expect(result.error, contains('oops'));
    });
  });
}
