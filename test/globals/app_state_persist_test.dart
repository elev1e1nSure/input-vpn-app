import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:input_vpn/core/di.dart';
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
      SharedPreferences.setMockInitialValues({});
      sharedPrefs = await SharedPreferences.getInstance();
      configureDependencies(sharedPrefs);
      mockVpn = _MockVpnService();
      mockSubs = _MockSubscriptionService();
      when(() => mockVpn.watchStatus()).thenAnswer((_) => const Stream.empty());
      when(() => mockVpn.watchStats()).thenAnswer((_) => const Stream.empty());
      when(() => mockVpn.dispose()).thenAnswer((_) => Future.value());
      state = AppState(vpnService: mockVpn, subscriptionService: mockSubs);
      await pumpEventQueue();
    });

    tearDown(() {
      state.dispose();
      getIt.reset();
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
