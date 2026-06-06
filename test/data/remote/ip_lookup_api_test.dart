import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/data/remote/ip_lookup_api.dart';
import 'package:mocktail/mocktail.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('IpLookupApi', () {
    late IpLookupApi api;
    late _MockDio mockDio;

    setUp(() {
      mockDio = _MockDio();
      api = IpLookupApi(dio: mockDio);
    });

    test('fetchPublicIp returns ip on success', () async {
      final response = Response<String>(
        data: '1.2.3.4',
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<String>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await api.fetchPublicIp();
      expect(result.isSuccess, true);
      expect(result.value, '1.2.3.4');
    });

    test('fetchPublicIp returns failure on empty data', () async {
      final response = Response<String>(
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<String>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await api.fetchPublicIp();
      expect(result.isFailure, true);
    });

    test('fetchCountryCode returns country code on success', () async {
      final response = Response<Map<String, dynamic>>(
        data: <String, dynamic>{'country': 'US'},
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final result = await api.fetchCountryCode();
      expect(result.isSuccess, true);
      expect(result.value, 'US');
    });

    test('fetchCountryCode returns failure on DioException', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      ));

      final result = await api.fetchCountryCode();
      expect(result.isFailure, true);
      expect(result.error, contains('connectionTimeout'));
    });
  });
}
