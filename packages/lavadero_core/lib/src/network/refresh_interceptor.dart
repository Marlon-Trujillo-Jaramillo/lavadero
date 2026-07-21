import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import '../models/auth_tokens.dart';

/// Intercepta respuestas `401` de requests autenticadas, dispara un refresh
/// de token (una sola vez, aunque lleguen varios 401 en paralelo) y reintenta
/// la request original exactamente una vez con el nuevo access token.
///
/// Para evitar loops infinitos:
/// - Los 401 de los propios endpoints de `/auth/*` NO disparan refresh.
/// - Cada request solo se reintenta una vez (`extra['lavadero_retried']`).
/// - El refresh en sí se hace con un [Dio] "pelado" ([refreshDio], sin este
///   interceptor ni el de auth) para no volver a entrar en este mismo flujo.
/// - Refreshes concurrentes se deduplican con un único [Future] compartido.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor({
    required Dio retryDio,
    required Dio refreshDio,
    required this.tokenStorage,
    this.onSessionExpired,
  })  : _retryDio = retryDio,
        _refreshDio = refreshDio;

  final Dio _retryDio;
  final Dio _refreshDio;
  final TokenStorage tokenStorage;

  /// Se invoca si el refresh falla (refresh token inválido/expirado): la app
  /// debe tratarlo como sesión cerrada y volver a la pantalla de login.
  final void Function()? onSessionExpired;

  static const _retriedFlag = 'lavadero_retried';

  Future<String>? _inFlightRefresh;

  bool _isAuthEndpoint(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/register') ||
      path.contains('/auth/refresh');

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final requestOptions = err.requestOptions;
    final alreadyRetried = requestOptions.extra[_retriedFlag] == true;

    if (response?.statusCode != 401 ||
        _isAuthEndpoint(requestOptions.path) ||
        alreadyRetried) {
      return handler.next(err);
    }

    try {
      final newAccessToken = await _refreshAccessToken();
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      requestOptions.extra[_retriedFlag] = true;
      final retriedResponse = await _retryDio.fetch(requestOptions);
      return handler.resolve(retriedResponse);
    } catch (_) {
      await tokenStorage.clear();
      onSessionExpired?.call();
      return handler.next(err);
    }
  }

  Future<String> _refreshAccessToken() {
    return _inFlightRefresh ??= _doRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<String> _doRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('No hay refresh token almacenado.');
    }

    final response = await _refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final tokens = AuthTokens.fromJson(response.data!);
    await tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return tokens.accessToken;
  }
}
