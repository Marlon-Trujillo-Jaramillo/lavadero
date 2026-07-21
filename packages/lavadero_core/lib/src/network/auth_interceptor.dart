import 'package:dio/dio.dart';

import '../auth/token_storage.dart';

/// Agrega el header `Authorization: Bearer <accessToken>` a toda request que
/// no sea uno de los endpoints públicos de auth/tenants.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage});

  final TokenStorage tokenStorage;

  static const _publicPathFragments = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/tenants',
  ];

  bool _isPublic(String path) =>
      _publicPathFragments.any((fragment) => path.contains(fragment));

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path) &&
        !options.headers.containsKey('Authorization')) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }
}
