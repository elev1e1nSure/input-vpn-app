import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';

void main() {
  group('PrefsDataSource', () {
    late PrefsDataSource source;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      source = PrefsDataSource(prefs);
    });

    test('getBool returns default when key absent', () {
      expect(source.getBool('missing'), false);
      expect(source.getBool('missing', defaultValue: true), true);
    });

    test('setBool stores and getBool reads back', () async {
      await source.setBool('flag', true);
      expect(source.getBool('flag'), true);
      await source.setBool('flag', false);
      expect(source.getBool('flag'), false);
    });

    test('getInt returns default when key absent', () {
      expect(source.getInt('missing'), 0);
      expect(source.getInt('missing', defaultValue: 42), 42);
    });

    test('setInt stores and getInt reads back', () async {
      await source.setInt('port', 1080);
      expect(source.getInt('port'), 1080);
    });

    test('getString returns null when key absent', () {
      expect(source.getString('missing'), null);
    });

    test('setString stores and getString reads back', () async {
      await source.setString('dns', '1.1.1.1');
      expect(source.getString('dns'), '1.1.1.1');
    });

    test('getJson delegates to getString', () async {
      await source.setJson('config', '{"a":1}');
      expect(source.getJson('config'), '{"a":1}');
    });

    test('remove deletes key', () async {
      await source.setBool('temp', true);
      expect(source.getBool('temp'), true);
      await source.remove('temp');
      expect(source.getBool('temp'), false);
    });

    test('getKeys returns all keys', () async {
      await source.setBool('a', true);
      await source.setString('b', 'x');
      expect(source.getKeys(), containsAll(<String>['a', 'b']));
    });
  });
}
