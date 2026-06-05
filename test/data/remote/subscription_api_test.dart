import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/data/remote/subscription_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
    registerFallbackValue(CancelToken());
  });

  group('SubscriptionApi', () {
    late SubscriptionApi api;
    late _MockDio mockDio;

    setUp(() {
      mockDio = _MockDio();
      api = SubscriptionApi(dio: mockDio);
    });

    test('fetch delegates GET to dio and returns body + headers', () async {
      const url = 'https://example.com/sub';
      final response = Response<String>(
        data: 'vless://a@b:443',
        requestOptions: RequestOptions(path: url),
      );
      when(
        () => mockDio.get<String>(
          url,
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await api.fetch(url);
      expect(result.body, 'vless://a@b:443');
      verify(
        () => mockDio.get<String>(
          url,
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('fetch returns empty body when data is null', () async {
      const url = 'https://example.com/sub';
      final response = Response<String>(
        requestOptions: RequestOptions(path: url),
      );
      when(
        () => mockDio.get<String>(
          url,
          cancelToken: any(named: 'cancelToken'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await api.fetch(url);
      expect(result.body, '');
    });
  });
}
