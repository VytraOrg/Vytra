import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheManager {
  static const String _userBox = 'user_box';
  static const String _apiBox = 'api_cache_box';
  static const String _settingsBox = 'settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Setup encryption for sensitive data
    const secureStorage = FlutterSecureStorage();
    var encryptionKeyString = await secureStorage.read(key: 'encryptionKey');
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      await secureStorage.write(key: 'encryptionKey', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }
    final encryptionKey = base64Url.decode(encryptionKeyString);

    // Open boxes
    await Hive.openBox(_userBox, encryptionCipher: HiveAesCipher(encryptionKey));
    await Hive.openBox(_apiBox);
    await Hive.openBox(_settingsBox);
  }

  // --- API Response Caching ---
  static Future<void> cacheResponse(String key, dynamic data) async {
    final box = Hive.box(_apiBox);
    await box.put(key, {
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static dynamic getCachedResponse(String key, {Duration? maxAge}) {
    final box = Hive.box(_apiBox);
    final cached = box.get(key);
    if (cached == null) return null;

    if (maxAge != null) {
      final timestamp = cached['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > maxAge.inMilliseconds) {
        box.delete(key);
        return null;
      }
    }
    return cached['data'];
  }

  // --- User Session Caching ---
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    final box = Hive.box(_userBox);
    await box.put('current_user', userData);
  }

  static Map<String, dynamic>? getUser() {
    final box = Hive.box(_userBox);
    final data = box.get('current_user');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> clearAll() async {
    await Hive.box(_apiBox).clear();
    await Hive.box(_userBox).clear();
    await Hive.box(_settingsBox).clear();
  }
}
