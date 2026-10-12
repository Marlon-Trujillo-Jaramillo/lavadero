import 'package:dio/dio.dart';

import '../models/reserva.dart';
import '../models/resumen_ventas.dart';
import '../models/sucursal.dart';
import '../network/api_exception.dart';

/// Cliente de agenda/reservas (`/api/v1/agenda/reservas`) y de sucursales (`/api/v1/sucursales`,
/// necesario para elegir dónde reservar / de qué sucursal es la agenda del empleado).
class SchedulingRepository {
  SchedulingRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Sucursal>> listarSucursales() async {
    try {
      final response = await _dio.get<List<dynamic>>('/sucursales');
      return (response.data ?? [])
          .map((json) => Sucursal.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Alta de una sucursal adicional (`ADMIN_TENANT`) — antes de esto, la única forma de tener más
  /// de una sucursal era una inserción manual en la base de datos.
  Future<Sucursal> crearSucursal({
    required String nombre,
    String? direccion,
    required int capacidadSimultanea,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/sucursales',
        data: {'nombre': nombre, 'direccion': direccion, 'capacidadSimultanea': capacidadSimultanea},
      );
      return Sucursal.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Sucursal> actualizarSucursal({
    required String id,
    required String nombre,
    String? direccion,
    required int capacidadSimultanea,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/sucursales/$id',
        data: {'nombre': nombre, 'direccion': direccion, 'capacidadSimultanea': capacidadSimultanea},
      );
      return Sucursal.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Cliente: reserva un servicio en una sucursal para un horario.
  Future<Reserva> crear({
    required String sucursalId,
    required String servicioId,
    required DateTime fechaHoraInicio,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/agenda/reservas',
        data: {
          'sucursalId': sucursalId,
          'servicioId': servicioId,
          'fechaHoraInicio': fechaHoraInicio.toUtc().toIso8601String(),
        },
      );
      return Reserva.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Cliente: sus propias reservas (cualquier estado).
  Future<List<Reserva>> misReservas() async {
    try {
      final response = await _dio.get<List<dynamic>>('/agenda/reservas/mias');
      return (response.data ?? [])
          .map((json) => Reserva.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Empleado/admin: agenda de una sucursal para un día.
  Future<List<Reserva>> agendaDelDia({required String sucursalId, required DateTime fecha}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/agenda/reservas',
        queryParameters: {
          'sucursalId': sucursalId,
          // El backend espera un ISO date (yyyy-MM-dd), no fecha-hora completa.
          'fecha': fecha.toIso8601String().substring(0, 10),
        },
      );
      return (response.data ?? [])
          .map((json) => Reserva.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Admin: resumen de ventas (ingresos, reservas completadas, servicios más pedidos) en un rango.
  Future<ResumenVentas> resumenVentas({required DateTime desde, required DateTime hasta}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/agenda/reportes/resumen',
        queryParameters: {
          'desde': desde.toIso8601String().substring(0, 10),
          'hasta': hasta.toIso8601String().substring(0, 10),
        },
      );
      return ResumenVentas.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Reserva> iniciar(String reservaId) => _cambiarEstado(reservaId, 'iniciar');

  Future<Reserva> completar(String reservaId) => _cambiarEstado(reservaId, 'completar');

  Future<Reserva> cancelar(String reservaId) => _cambiarEstado(reservaId, 'cancelar');

  Future<Reserva> _cambiarEstado(String reservaId, String accion) async {
    try {
      final response =
          await _dio.patch<Map<String, dynamic>>('/agenda/reservas/$reservaId/$accion');
      return Reserva.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
