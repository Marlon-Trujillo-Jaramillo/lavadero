import 'package:dio/dio.dart';

import '../models/service_item.dart';
import '../network/api_exception.dart';

/// Cliente del catálogo de servicios de un tenant (`/api/v1/catalogo/servicios`).
class CatalogRepository {
  CatalogRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Administración: todos los servicios del tenant actual (activos e inactivos).
  Future<List<ServiceItem>> listar() async {
    try {
      final response = await _dio.get<List<dynamic>>('/catalogo/servicios');
      return (response.data ?? [])
          .map((json) => ServiceItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Cliente/empleado: solo servicios activos.
  Future<List<ServiceItem>> listarActivos() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/catalogo/servicios/activos',
      );
      return (response.data ?? [])
          .map((json) => ServiceItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceItem> crear({
    required String nombre,
    String? descripcion,
    required int duracionEstimadaMinutos,
    required double precio,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/catalogo/servicios',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'duracionEstimadaMinutos': duracionEstimadaMinutos,
          'precio': precio,
        },
      );
      return ServiceItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceItem> actualizar({
    required String id,
    required String nombre,
    String? descripcion,
    required int duracionEstimadaMinutos,
    required double precio,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/catalogo/servicios/$id',
        data: {
          'nombre': nombre,
          'descripcion': descripcion,
          'duracionEstimadaMinutos': duracionEstimadaMinutos,
          'precio': precio,
        },
      );
      return ServiceItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ServiceItem> cambiarEstado({
    required String id,
    required bool activo,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/catalogo/servicios/$id/estado',
        data: {'activo': activo},
      );
      return ServiceItem.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
