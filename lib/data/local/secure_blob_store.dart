import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Encrypted-at-rest store for sensitive credential blobs (subscription URLs,
/// raw share links, parsed uuid/password/reality/sni, …).
///
/// On Windows, [FlutterSecureStorage] is backed by DPAPI, so values are
/// encrypted with the current user's keys instead of sitting in cleartext in
/// SharedPreferences (which on Windows is a plain JSON file under the user
/// profile, readable by any process running as that user).
///
/// The existing persistence layers read/write synchronously, so this store
/// keeps an in-memory cache populated once at startup ([init]) and writes
/// through to secure storage asynchronously. Reads ([get]) hit the cache.
class SecureBlobStore {
  SecureBlobStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  final Map<String, String> _cache = <String, String>{};
  bool _ready = false;

  /// Keys that hold sensitive data and must live in encrypted storage.
  static const List<String> sensitiveKeys = <String>[
    'userConfigs',
    'userServers',
    'parsedByServerId',
  ];

  /// Load [sensitiveKeys] into the cache. If a key is absent from secure
  /// storage but present (in cleartext) in [migrateFrom], it is migrated:
  /// copied into secure storage and removed from prefs. Idempotent.
  Future<void> init({SharedPreferences? migrateFrom}) async {
    for (final key in sensitiveKeys) {
      String? value;
      try {
        value = await _storage.read(key: key);
      } on Exception catch (e) {
        debugPrint('SecureBlobStore: read "$key" failed: $e');
      }

      if (value == null && migrateFrom != null) {
        final legacy = migrateFrom.getString(key);
        if (legacy != null && legacy.isNotEmpty) {
          try {
            await _storage.write(key: key, value: legacy);
            await migrateFrom.remove(key);
            value = legacy;
            debugPrint('SecureBlobStore: migrated "$key" to secure storage');
          } on Exception catch (e) {
            debugPrint('SecureBlobStore: migrate "$key" failed: $e');
          }
        }
      }

      if (value != null) _cache[key] = value;
    }
    _ready = true;
  }

  /// Synchronous read from the in-memory cache. Returns null if absent.
  String? get(String key) {
    assert(_ready, 'SecureBlobStore.get called before init()');
    return _cache[key];
  }

  /// Update the cache immediately and write through to secure storage.
  void set(String key, String value) {
    _cache[key] = value;
    _storage.write(key: key, value: value).catchError((Object e) {
      debugPrint('SecureBlobStore: write "$key" failed: $e');
    });
  }

  /// Remove from cache and secure storage.
  void remove(String key) {
    _cache.remove(key);
    _storage.delete(key: key).catchError((Object e) {
      debugPrint('SecureBlobStore: delete "$key" failed: $e');
    });
  }
}

/// Global secure store initialized at app startup, alongside [sharedPrefs].
late SecureBlobStore secureStore;
