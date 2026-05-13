import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/services/dio_factory.dart';

void main() {
  group('DioFactory', () {
    test('forClashApi has short timeouts', () {
      final dio = DioFactory.forClashApi();
      expect(dio.options.connectTimeout, const Duration(seconds: 2));
      expect(dio.options.receiveTimeout, const Duration(seconds: 5));
    });

    test('forSubscriptions has long timeouts and User-Agent', () {
      final dio = DioFactory.forSubscriptions();
      expect(dio.options.connectTimeout, const Duration(seconds: 15));
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(dio.options.followRedirects, true);
      expect(dio.options.responseType.toString(), 'ResponseType.plain');
      expect(
        dio.options.headers['User-Agent'],
        'InputVPN/1.0',
      );
    });
  });
}
