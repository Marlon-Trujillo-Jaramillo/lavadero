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

  /// Escrituras en SERIE, nunca en paralelo: en web, `flutter_secure_storage`
  /// genera la clave de cifrado (WebCrypto) de forma perezosa en la primera
  /// escritura. Dos escrituras simultáneas generaban dos claves y la segunda
  /// pisaba a la primera, dejando un token cifrado con una clave perdida
  /// (`OperationError` al leerlo): el primer request tras el login fallaba
  /// y recargar la página rompía la sesión.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> readAccessToken() => _leer(_accessTokenKey);

  Future<String?> readRefreshToken() => _leer(_refreshTokenKey);

  /// Un valor ilegible (clave de cifrado perdida, almacenamiento corrupto) se
  /// trata como "sin sesión" y se limpia, en vez de propagar una excepción
  /// que dejaba la app en un estado roto: el usuario simplemente vuelve al
  /// login.
  Future<String?> _leer(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> saveUserProfile(UserProfile profile) =>
      _storage.write(key: _userProfileKey, value: jsonEncode(profile.toJson()));

  Future<UserProfile?> readUserProfile() async {
    final raw = await _leer(_userProfileKey);
    if (raw == null) return null;
    try {
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    for (final key in [_accessTokenKey, _refreshTokenKey, _userProfileKey]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Borrar es idempotente: si una clave ya no se puede tocar, seguir.
      }
    }
  }

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
