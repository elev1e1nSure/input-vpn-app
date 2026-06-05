import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:input_vpn/data/remote/ip_lookup_api.dart';

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
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<String>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final ip = await api.fetchPublicIp();
      expect(ip, '1.2.3.4');
    });

    test('fetchPublicIp returns null on empty data', () async {
      final response = Response<String>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<String>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final ip = await api.fetchPublicIp();
      expect(ip, null);
    });

    test('fetchCountryCode returns country code on success', () async {
      final response = Response<Map<String, dynamic>>(
        data: <String, dynamic>{'countryCode': 'US'},
        statusCode: 200,
        requestOptions: RequestOptions(),
      );
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => response);

      final country = await api.fetchCountryCode();
      expect(country, 'US');
    });

    test('fetchCountryCode returns null on error', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          options: any(named: 'options'),
        ),
      ).thenThrow(DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionTimeout,
      ));

      final country = await api.fetchCountryCode();
      expect(country, null);
    });
  });
}
