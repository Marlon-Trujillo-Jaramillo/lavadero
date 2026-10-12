import 'package:dio/dio.dart';

import '../models/subscription_plan.dart';
import '../models/tenant_summary.dart';
import '../network/api_exception.dart';

/// Búsqueda pública de tenants (`tenant_selection`) + administración de
/// planes de suscripción (`/api/v1/plataforma/planes`, solo SUPER_ADMIN).
///
/// Ambos son datos de PLATAFORMA (no de un tenant específico), de ahí que
/// convivan en el mismo repositorio en vez de uno por concepto.
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

  Future<List<SubscriptionPlan>> listarPlanes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/plataforma/planes');
      return (response.data ?? [])
          .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SubscriptionPlan> crearPlan({
    required String nombre,
    required double precio,
    required int maxSucursales,
    required int maxEmpleados,
    required List<String> features,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/plataforma/planes',
        data: {
          'nombre': nombre,
          'precio': precio,
          'maxSucursales': maxSucursales,
          'maxEmpleados': maxEmpleados,
          'features': features,
        },
      );
      return SubscriptionPlan.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SubscriptionPlan> actualizarPlan({
    required String id,
    required String nombre,
    required double precio,
    required int maxSucursales,
    required int maxEmpleados,
    required List<String> features,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/plataforma/planes/$id',
        data: {
          'nombre': nombre,
          'precio': precio,
          'maxSucursales': maxSucursales,
          'maxEmpleados': maxEmpleados,
          'features': features,
        },
      );
      return SubscriptionPlan.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
