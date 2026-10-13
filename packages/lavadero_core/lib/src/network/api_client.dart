import 'package:dio/dio.dart';

import '../auth/token_storage.dart';
import 'auth_interceptor.dart';
import 'refresh_interceptor.dart';
import 'tenant_interceptor.dart';

/// Cliente HTTP central de las apps: un [Dio] configurado con `baseUrl` +
/// `/api/v1`, y los tres interceptores del contrato (tenant, auth, refresh).
///
/// Uso típico (composición vía Riverpod, ver `app/di` en cada app):
/// ```dart
/// final apiClient = ApiClient(
///   baseUrl: 'https://api.dev.lavadero.app',
///   tokenStorage: tokenStorage,
///   tenantSlugProvider: () => tenantSlugNotifier.value,
/// );
/// ```
class ApiClient {
  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    String? Function()? tenantSlugProvider,
    void Function()? onSessionExpired,
    List<Interceptor> extraInterceptors = const [],
  }) : dio = Dio(
         BaseOptions(
           baseUrl: _withApiPrefix(baseUrl),
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           contentType: 'application/json',
         ),
       ),
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: _withApiPrefix(baseUrl),
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 15),
           contentType: 'application/json',
         ),
       ) {
    dio.interceptors.addAll([
      TenantInterceptor(tenantSlugProvider: tenantSlugProvider ?? () => null),
      AuthInterceptor(tokenStorage: tokenStorage),
      RefreshInterceptor(
        retryDio: dio,
        refreshDio: _refreshDio,
        tokenStorage: tokenStorage,
        onSessionExpired: onSessionExpired,
      ),
      ...extraInterceptors,
    ]);
  }

  /// Dio principal, con el stack completo de interceptores. Las apps y
  /// repositorios deben usar esta instancia para todas las llamadas.
  final Dio dio;

  /// Dio "pelado" (sin interceptores) usado internamente solo para el POST
  /// de refresh, evitando que ese request vuelva a disparar este mismo flujo.
  final Dio _refreshDio;

  static String _withApiPrefix(String baseUrl) {
    final trimmed = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return trimmed.endsWith('/api/v1') ? trimmed : '$trimmed/api/v1';
  }
}
