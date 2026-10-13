import 'package:dio/dio.dart';

/// Agrega el header `X-Tenant-Slug` cuando hay un tenant seleccionado
/// (proveniente de la pantalla de selección de tenant) y la request todavía
/// no trae ese header explícito (p. ej. login ya lo setea a mano con el slug
/// elegido en el momento, que puede diferir del último tenant "recordado").
class TenantInterceptor extends Interceptor {
  TenantInterceptor({required this.tenantSlugProvider});

  /// Devuelve el slug del tenant actualmente seleccionado, o `null` si no
  /// hay ninguno (p. ej. antes de pasar por tenant_selection).
  final String? Function() tenantSlugProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey('X-Tenant-Slug')) {
      final slug = tenantSlugProvider();
      if (slug != null && slug.isNotEmpty) {
        options.headers['X-Tenant-Slug'] = slug;
      }
    }
    handler.next(options);
  }
}
