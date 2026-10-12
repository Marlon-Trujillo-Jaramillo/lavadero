import 'package:dio/dio.dart';

import '../models/empleado.dart';
import '../network/api_exception.dart';

/// Administración de staff del tenant actual (`/api/v1/empleados`) — antes de esto, la única
/// forma de tener un empleado era una fila insertada a mano en la base de datos.
class EmpleadoRepository {
  EmpleadoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Empleado>> listar() async {
    try {
      final response = await _dio.get<List<dynamic>>('/empleados');
      return (response.data ?? [])
          .map((json) => Empleado.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Empleado> crear({
    required String email,
    required String password,
    required String nombre,
    String? sucursalId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/empleados',
        data: {
          'email': email,
          'password': password,
          'nombre': nombre,
          'sucursalId': sucursalId,
        },
      );
      return Empleado.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
