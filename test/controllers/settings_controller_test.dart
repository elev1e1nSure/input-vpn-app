import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:input_vpn/controllers/settings_controller.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';

void main() {
  group('SettingsController', () {
    late SettingsController controller;
    late PrefsDataSource prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      prefs = PrefsDataSource(sp);
      controller = SettingsController(prefs: prefs);
    });

    tearDown(() => controller.dispose());

    test('default values', () {
      expect(controller.locale, const Locale('en'));
      expect(controller.isDarkMode, true);
      expect(controller.connectOnBoot, false);
      expect(controller.autoLaunch, false);
      expect(controller.minimizeToTray, false);
      expect(controller.customDns, 'Default');
      expect(controller.dnsPreset, 'cloudflare');
      expect(controller.proxyPort, 11080);
      expect(controller.dnsCustomId, null);
    });

    test('setLocale changes locale and notifies', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.setLocale('ru');
      expect(controller.locale, const Locale('ru'));
      expect(count, 1);
    });

    test('setLocale with same value does not notify', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.setLocale('en');
      expect(count, 0);
    });

    test('setThemeMode changes mode and notifies', () {
      var count = 0;
      controller.addListener(() => count++);
      controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);
      expect(count, 1);
    });

    test('setConnectOnBoot persists and notifies', () {
      controller.setConnectOnBoot(true);
      expect(controller.connectOnBoot, true);
      expect(prefs.getBool('connectOnBoot'), true);
    });

    test('setAutoLaunch persists and notifies', () {
      controller.setAutoLaunch(true);
      expect(controller.autoLaunch, true);
      expect(prefs.getBool('autoLaunch'), true);
    });

    test('setMinimizeToTray persists and notifies', () {
      controller.setMinimizeToTray(true);
      expect(controller.minimizeToTray, true);
      expect(prefs.getBool('minimizeToTray'), true);
    });

    test('setCustomDns persists and notifies', () {
      controller.setCustomDns('1.1.1.1');
      expect(controller.customDns, '1.1.1.1');
      expect(prefs.getString('customDns'), '1.1.1.1');
    });

    test('setDnsPreset persists and notifies', () {
      controller.setDnsPreset('google');
      expect(controller.dnsPreset, 'google');
      expect(prefs.getString('dnsPreset'), 'google');
    });

    test('selectCustomDns persists', () {
      controller.selectCustomDns('profile-1');
      expect(controller.dnsCustomId, 'profile-1');
      expect(prefs.getString('dnsCustomId'), 'profile-1');
    });

    test('setProxyPort persists and notifies', () {
      controller.setProxyPort(1080);
      expect(controller.proxyPort, 1080);
      expect(prefs.getInt('proxyPort'), 1080);
    });

    test('currentDnsServers returns cloudflare preset by default', () {
      expect(controller.currentDnsServers, ['1.1.1.1', '1.0.0.1']);
    });

    test('saveCustomDnsProfile adds profile', () {
      final profile = CustomDnsProfile(
        id: 'p1',
        name: 'Test',
        primary: '9.9.9.9',
      );
      controller.saveCustomDnsProfile(profile);
      expect(controller.customDnsProfiles.length, 1);
      expect(controller.customDnsProfiles.first.id, 'p1');
    });

    test('deleteCustomDnsProfile removes profile', () {
      final profile = CustomDnsProfile(
        id: 'p1',
        name: 'Test',
        primary: '9.9.9.9',
      );
      controller.saveCustomDnsProfile(profile);
      controller.deleteCustomDnsProfile('p1');
      expect(controller.customDnsProfiles.isEmpty, true);
    });

    test('deleteCustomDnsProfile clears selection if active', () {
      final profile = CustomDnsProfile(
        id: 'p1',
        name: 'Test',
        primary: '9.9.9.9',
      );
      controller.saveCustomDnsProfile(profile);
      controller.selectCustomDns('p1');
      expect(controller.dnsCustomId, 'p1');

      controller.deleteCustomDnsProfile('p1');
      expect(controller.dnsCustomId, null);
    });

    test('selectedCustomDnsProfile returns null when no selection', () {
      expect(controller.selectedCustomDnsProfile, null);
    });

    test('selectedCustomDnsProfile returns profile when selected', () {
      final profile = CustomDnsProfile(
        id: 'p1',
        name: 'Test',
        primary: '9.9.9.9',
      );
      controller.saveCustomDnsProfile(profile);
      controller.selectCustomDns('p1');
      expect(controller.selectedCustomDnsProfile?.id, 'p1');
    });
  });
}
