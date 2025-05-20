import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userIdKey = 'user_id';
  static const _deviceIdKey = 'device_id';
  static const _guestAttemptsKey = 'guest_attempts'; // New key for attempt count

  static Future<void> storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> storeUserName(String userName) async {
    await _storage.write(key: _userNameKey, value: userName);
  }

  static Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  static Future<void> storeUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> storeDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  static Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // New method to store guest attempt count
  static Future<void> storeGuestAttempts(int attempts) async {
    await _storage.write(key: _guestAttemptsKey, value: attempts.toString());
  }

  // New method to retrieve guest attempt count
  static Future<int> getGuestAttempts() async {
    final attemptsString = await _storage.read(key: _guestAttemptsKey);
    return int.tryParse(attemptsString ?? '0') ?? 0;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
}