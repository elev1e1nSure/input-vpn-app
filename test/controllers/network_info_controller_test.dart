import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:input_vpn/controllers/network_info_controller.dart';
import 'package:input_vpn/services/ip_service.dart';

class _MockIpService extends Mock implements IpService {}

void main() {
  group('NetworkInfoController', () {
    late NetworkInfoController controller;

    setUp(() {
      controller = NetworkInfoController();
    });

    tearDown(() => controller.dispose());

    test('initial state is null', () {
      expect(controller.publicIp, null);
      expect(controller.countryCode, null);
    });

    test('clear resets values', () {
      controller.clear();
      expect(controller.publicIp, null);
      expect(controller.countryCode, null);
    });

    test('notifies listeners on clear', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.clear();
      expect(count, 1);
    });

    test('removeListener stops notifications', () {
      var count = 0;
      void listener() => count++;
      controller.addListener(listener);
      controller.clear();
      expect(count, 1);
      controller.removeListener(listener);
      controller.clear();
      expect(count, 1);
    });
  });
}
