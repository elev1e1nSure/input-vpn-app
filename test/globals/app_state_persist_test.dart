import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:input_vpn/core/di.dart';
import 'package:input_vpn/data/local/secure_blob_store.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/globals/shared_prefs.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockVpnService extends Mock implements VpnService {}

class _MockSubscriptionService extends Mock implements SubscriptionService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('AppState persist helpers', () {
    late AppState state;
    late _MockVpnService mockVpn;
    late _MockSubscriptionService mockSubs;

    setUp(() async {
      // In-memory mock for the flutter_secure_storage method channel so the
      // credential store works deterministically without native plugins.
      final fakeSecure = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'read':
              return fakeSecure[args['key'] as String];
            case 'write':
              fakeSecure[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              fakeSecure.remove(args['key'] as String);
              return null;
            case 'readAll':
              return Map<String, String>.of(fakeSecure);
            case 'deleteAll':
              fakeSecure.clear();
              return null;
            case 'containsKey':
              return fakeSecure.containsKey(args['key'] as String);
          }
          return null;
        },
      );

      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
      secureStore = SecureBlobStore();
      await secureStore.init();
      getIt.allowReassignment = true;
      configureDependencies(sharedPrefs);
      mockVpn = _MockVpnService();
      mockSubs = _MockSubscriptionService();
      when(() => mockVpn.watchStatus()).thenAnswer((_) => const Stream.empty());
      when(() => mockVpn.watchStats()).thenAnswer((_) => const Stream.empty());
      when(() => mockVpn.dispose()).thenAnswer((_) => Future.value());
      state = AppState(vpnService: mockVpn, subscriptionService: mockSubs);
      await pumpEventQueue();
    });

    tearDown(() async {
      state.dispose();
      await getIt.reset();
    });

    test('setConnectOnBoot does not notify when value unchanged', () {
      var count = 0;
      state.addListener(() => count++);
      state.setConnectOnBoot(false); // default is false
      expect(count, 0);
    });

    test('setConnectOnBoot notifies when value changes', () {
      var count = 0;
      state.addListener(() => count++);
      state.setConnectOnBoot(true);
      expect(count, 1);
      expect(state.connectOnBoot, true);
    });

    test('setCustomDns does not notify when value unchanged', () {
      var count = 0;
      state.addListener(() => count++);
      state.setCustomDns('Default'); // default is 'Default'
      expect(count, 0);
    });

    test('setCustomDns notifies when value changes', () {
      var count = 0;
      state.addListener(() => count++);
      state.setCustomDns('1.1.1.1');
      expect(count, 1);
      expect(state.customDns, '1.1.1.1');
    });

    test('setProxyPort does not notify when value unchanged', () {
      var count = 0;
      state.addListener(() => count++);
      state.setProxyPort(11080); // default is 11080
      expect(count, 0);
    });

    test('setProxyPort notifies when value changes', () {
      var count = 0;
      state.addListener(() => count++);
      state.setProxyPort(1080);
      expect(count, 1);
      expect(state.proxyPort, 1080);
    });
  });
}
