import 'package:dio/dio.dart';

import '../models/tenant_summary.dart';
import '../network/api_exception.dart';

/// Búsqueda pública de tenants para la pantalla `tenant_selection`.
///
/// Vive junto a `auth/` (en vez de en un paquete `tenants/` aparte) porque su
/// único consumidor hoy es el flujo de selección-de-tenant -> login, y no
/// justifica una carpeta propia con un solo archivo.
class TenantRepository {
  TenantRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TenantSummary>> search(String query) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/tenants',
        queryParameters: {'query': query},
      );
      return (response.data ?? [])
          .map((json) => TenantSummary.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
