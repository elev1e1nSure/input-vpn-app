import 'package:shared_preferences/shared_preferences.dart';

/// Typed abstraction over [SharedPreferences] to avoid raw key strings
/// and type-unsafe reads throughout the app.
class PrefsDataSource {
  const PrefsDataSource(this._prefs);

  final SharedPreferences _prefs;

  // --- Booleans ---
  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  // --- Integers ---
  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  // --- Strings ---
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  // --- JSON / complex objects ---
  String? getJson(String key) => _prefs.getString(key);

  Future<bool> setJson(String key, String json) =>
      _prefs.setString(key, json);

  // --- Removal ---
  Future<bool> remove(String key) => _prefs.remove(key);

  // --- Bulk read for debugging ---
  Set<String> getKeys() => _prefs.getKeys();
}
