import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:input_vpn/controllers/vpn_connection_controller.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/parsed_config.dart';
import 'package:input_vpn/models/proxy_type.dart';
import 'package:input_vpn/services/vpn_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockVpnService extends Mock implements VpnService {}

class _FakeParsedConfig extends Fake implements ParsedConfig {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeParsedConfig());
  });

  group('VpnConnectionController', () {
    late VpnConnectionController controller;
    late _MockVpnService mockVpn;
    late StreamController<ConnectionStatus> statusController;

    setUp(() {
      mockVpn = _MockVpnService();
      statusController = StreamController<ConnectionStatus>.broadcast();
      when(() => mockVpn.watchStatus())
          .thenAnswer((_) => statusController.stream);
      when(() => mockVpn.dispose()).thenAnswer((_) => Future.value());
      when(() => mockVpn.disconnect()).thenAnswer((_) => Future.value());
      controller = VpnConnectionController(vpnService: mockVpn);
    });

    tearDown(() {
      controller.dispose();
      statusController.close();
    });

    test('initial state is disconnected', () {
      expect(controller.isConnected, false);
      expect(controller.isConnecting, false);
      expect(controller.isDisconnecting, false);
    });

    test('statusStream delegates to vpnService', () {
      expect(controller.statusStream, statusController.stream);
    });

    test('connect delegates to vpnService', () async {
      final config = _dummyConfig();
      when(() => mockVpn.connect(any())).thenAnswer((_) => Future.value());
      await controller.connect(config);
      verify(() => mockVpn.connect(config)).called(1);
    });

    test('isConnecting becomes true on Connecting status', () async {
      expect(controller.isConnecting, false);
      statusController.add(const Connecting());
      await pumpEventQueue();
      expect(controller.isConnecting, true);
      expect(controller.isConnected, false);
    });

    test('isConnected becomes true on Connected status', () async {
      statusController.add(const Connecting());
      statusController.add(Connected(since: DateTime.now()));
      await pumpEventQueue();
      expect(controller.isConnected, true);
      expect(controller.isConnecting, false);
    });

    test('isDisconnecting set during disconnect call', () async {
      // Fake connected state
      statusController.add(Connected(since: DateTime.now()));
      await pumpEventQueue();
      expect(controller.isConnected, true);
      // disconnect will set isDisconnecting, await mock, then clear
      final future = controller.disconnect();
      expect(controller.isDisconnecting, true);
      await future;
      expect(controller.isDisconnecting, false);
    });

    test('disconnected resets all flags', () async {
      statusController.add(const Connecting());
      statusController.add(Connected(since: DateTime.now()));
      await pumpEventQueue();
      statusController.add(const Disconnected());
      await pumpEventQueue();
      expect(controller.isConnected, false);
      expect(controller.isConnecting, false);
      expect(controller.isDisconnecting, false);
    });

    test('toggle connects when disconnected', () async {
      final config = _dummyConfig();
      when(() => mockVpn.connect(any())).thenAnswer((_) => Future.value());
      await controller.toggle(config);
      verify(() => mockVpn.connect(config)).called(1);
    });

    test('toggle disconnects when connected', () async {
      statusController.add(Connected(since: DateTime.now()));
      await pumpEventQueue();
      await controller.toggle(_dummyConfig());
      verify(() => mockVpn.disconnect()).called(1);
    });

    test('toggle does nothing when connecting', () async {
      statusController.add(const Connecting());
      await pumpEventQueue();
      await controller.toggle(_dummyConfig());
      verifyNever(() => mockVpn.disconnect());
    });

    test('concurrent connect is ignored', () async {
      final config = _dummyConfig();
      // Make connect hang
      when(() => mockVpn.connect(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      final f1 = controller.connect(config);
      // Second connect should be ignored because _operationInProgress is true
      await controller.connect(config);
      await f1;
      verify(() => mockVpn.connect(any())).called(1);
    });

    test('concurrent disconnect is ignored', () async {
      statusController.add(Connected(since: DateTime.now()));
      await pumpEventQueue();
      // Make disconnect hang
      when(() => mockVpn.disconnect()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      final f1 = controller.disconnect();
      // Second disconnect should be ignored
      await controller.disconnect();
      await f1;
      verify(() => mockVpn.disconnect()).called(1);
    });

    test('dispose does not call disconnect when already disconnected', () {
      verifyNever(() => mockVpn.disconnect());
    });

    test('isProxyMode / isServiceMode return false for generic VpnService', () {
      expect(controller.isProxyMode, false);
      expect(controller.isServiceMode, false);
      expect(controller.isReconnecting, false);
      expect(controller.reconnectAttempt, 0);
    });
  });
}

ParsedConfig _dummyConfig() => const ParsedConfig(
      type: ProxyType.vless,
      server: 'example.com',
      port: 443,
      remark: 'test',
      uuid: 'uuid',
      security: 'tls',
      raw: 'vless://uuid@example.com:443',
    );
