import 'package:dio/dio.dart';

import '../models/tipo_vehiculo.dart';
import '../models/vehiculo.dart';
import '../network/api_exception.dart';

/// "Mis vehículos" del cliente autenticado (`/api/v1/vehiculos`).
class VehiculoRepository {
  VehiculoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Vehiculo>> misVehiculos() async {
    try {
      final response = await _dio.get<List<dynamic>>('/vehiculos/mios');
      return response.data!
          .map((e) => Vehiculo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Vehiculo> registrar({
    required String placa,
    required TipoVehiculo tipo,
    String? marca,
    String? color,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/vehiculos',
        data: {
          'placa': placa,
          'tipo': tipo.wireValue,
          if (marca != null && marca.trim().isNotEmpty) 'marca': marca.trim(),
          if (color != null && color.trim().isNotEmpty) 'color': color.trim(),
        },
      );
      return Vehiculo.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Lo quita de la lista; las reservas que ya lo usaron conservan la placa.
  Future<void> archivar(String vehiculoId) async {
    try {
      await _dio.delete<void>('/vehiculos/$vehiculoId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
