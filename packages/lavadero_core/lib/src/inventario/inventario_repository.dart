import 'package:dio/dio.dart';

import '../models/inventario.dart';
import '../network/api_exception.dart';

/// Inventario de insumos (`/api/v1/inventario`).
class InventarioRepository {
  InventarioRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Insumos con su stock en [sucursalId] (los bajo mínimo primero).
  Future<List<InsumoStock>> insumos({required String sucursalId}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/inventario/insumos',
        queryParameters: {'sucursalId': sucursalId},
      );
      return response.data!
          .map((e) => InsumoStock.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Crea el insumo y devuelve su id. [costoUnitario] es por 1 ml, 1 g o 1
  /// unidad.
  Future<String> crearInsumo({
    required String nombre,
    required UnidadMedida unidad,
    required num costoUnitario,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventario/insumos',
        data: {
          'nombre': nombre.trim(),
          'unidad': unidad.wireValue,
          'costoUnitario': costoUnitario,
        },
      );
      return response.data!['id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MovimientoInventario> registrarEntrada({
    required String insumoId,
    required String sucursalId,
    required num cantidad,
    String? nota,
  }) => _movimiento('entradas', insumoId, sucursalId, cantidad, nota);

  /// Conteo físico: el stock pasa a ser [cantidadContada].
  Future<MovimientoInventario> ajustar({
    required String insumoId,
    required String sucursalId,
    required num cantidadContada,
    String? nota,
  }) => _movimiento('ajustes', insumoId, sucursalId, cantidadContada, nota);

  Future<void> fijarMinimo({
    required String insumoId,
    required String sucursalId,
    required num minimo,
  }) async {
    try {
      await _dio.put<void>(
        '/inventario/insumos/$insumoId/minimo',
        data: {'sucursalId': sucursalId, 'cantidad': minimo},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<MovimientoInventario>> movimientos({
    required String insumoId,
    required String sucursalId,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/inventario/insumos/$insumoId/movimientos',
        queryParameters: {'sucursalId': sucursalId},
      );
      return response.data!
          .map((e) => MovimientoInventario.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<CostoServicio>> costos() async {
    try {
      final response = await _dio.get<List<dynamic>>('/inventario/costos');
      return response.data!
          .map((e) => CostoServicio.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Reemplaza la receta del servicio: insumoId → cantidad por lavado.
  Future<void> definirReceta({
    required String servicioId,
    required Map<String, num> lineas,
  }) async {
    try {
      await _dio.put<void>(
        '/inventario/recetas/$servicioId',
        data: {
          'lineas': [
            for (final l in lineas.entries)
              {'insumoId': l.key, 'cantidad': l.value},
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<MovimientoInventario> _movimiento(
    String tipo,
    String insumoId,
    String sucursalId,
    num cantidad,
    String? nota,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/inventario/insumos/$insumoId/$tipo',
        data: {
          'sucursalId': sucursalId,
          'cantidad': cantidad,
          if (nota != null && nota.trim().isNotEmpty) 'nota': nota.trim(),
        },
      );
      return MovimientoInventario.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
