import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../models/auth_tokens.dart';
import '../models/user_profile.dart';
import '../network/api_exception.dart';
import 'token_storage.dart';

/// Coordina las llamadas de autenticación contra `/api/v1/auth/*` con la
/// persistencia de tokens en [TokenStorage]. El refresh "reactivo" (ante un
/// 401 durante una request cualquiera) ya lo resuelve `RefreshInterceptor`;
/// [refresh] aquí se expone además para refresh "proactivo" al iniciar la
/// app (ver `main_*.dart` bootstrap) cuando ya hay una sesión guardada.
class AuthRepository {
  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthResponse> login({
    required String tenantSlug,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(headers: {'X-Tenant-Slug': tenantSlug}),
      );
      final auth = AuthResponse.fromJson(response.data!);
      await _tokenStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      await _tokenStorage.saveUserProfile(auth.user);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AuthResponse> register({
    required String tenantSlug,
    required String email,
    required String password,
    required String nombre,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {'email': email, 'password': password, 'nombre': nombre},
        options: Options(headers: {'X-Tenant-Slug': tenantSlug}),
      );
      final auth = AuthResponse.fromJson(response.data!);
      await _tokenStorage.saveTokens(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      );
      await _tokenStorage.saveUserProfile(auth.user);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Restaura la sesión guardada localmente (sin llamar al backend): si hay
  /// tokens y un perfil de usuario cacheados, los devuelve para que el
  /// router pueda decidir de una vez el shell correcto (cliente/empleado).
  /// El backend no expone `GET /me`, por eso esta caché local es la única
  /// fuente de verdad del perfil entre sesiones de la app.
  Future<UserProfile?> restoreSession() async {
    if (!await _tokenStorage.hasSession()) return null;
    return _tokenStorage.readUserProfile();
  }

  /// Refresh explícito (p. ej. al abrir la app con una sesión guardada).
  /// Ante un fallo, limpia los tokens: la sesión se considera expirada.
  Future<AuthTokens> refresh() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw const ApiException(message: 'No hay sesión guardada.');
      }
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final tokens = AuthTokens.fromJson(response.data!);
      await _tokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      return tokens;
    } on DioException catch (e) {
      await _tokenStorage.clear();
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Si el logout remoto falla (p. ej. sin red), igual limpiamos la
      // sesión local: para el usuario, cerrar sesión debe ser inmediato.
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<bool> hasSession() => _tokenStorage.hasSession();
}
