import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_profile.dart';

/// Guarda/lee/borra el par de tokens (access + refresh) en almacenamiento
/// seguro del dispositivo (Keychain en iOS/macOS, EncryptedSharedPreferences
/// en Android, etc. vía `flutter_secure_storage`).
///
/// También cachea localmente el último [UserProfile] recibido en
/// login/register. El contrato de API no expone un endpoint `GET /me`, así
/// que esta caché es lo que permite restaurar sesión (mostrar el shell
/// correcto según roles) al reabrir la app sin forzar un login nuevo; ver
/// `AuthRepository.restoreSession()`.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'lavadero.access_token';
  static const _refreshTokenKey = 'lavadero.refresh_token';
  static const _userProfileKey = 'lavadero.user_profile';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveUserProfile(UserProfile profile) => _storage.write(
        key: _userProfileKey,
        value: jsonEncode(profile.toJson()),
      );

  Future<UserProfile?> readUserProfile() async {
    final raw = await _storage.read(key: _userProfileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _userProfileKey),
    ]);
  }

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
