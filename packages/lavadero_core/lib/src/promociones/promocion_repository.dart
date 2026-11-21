import 'package:dio/dio.dart';

import '../models/promocion.dart';
import '../network/api_exception.dart';

/// Promociones (`/api/v1/promociones`): el dueño las crea y ve sus
/// resultados; el cliente cotiza el precio antes de reservar.
class PromocionRepository {
  PromocionRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Promocion>> listar() async {
    try {
      final response = await _dio.get<List<dynamic>>('/promociones');
      return response.data!
          .map((e) => Promocion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// [codigo] y [usosMaximos] son de un cupón; [dias], [horaDesde] y
  /// [horaHasta] (`HH:mm`), de un precio por horario.
  Future<Promocion> crear({
    required String nombre,
    required TipoPromocion tipo,
    required TipoDescuento tipoDescuento,
    required num valorDescuento,
    required DateTime vigenteDesde,
    required DateTime vigenteHasta,
    String? codigo,
    int? usosMaximos,
    List<DiaSemana> dias = const [],
    String? horaDesde,
    String? horaHasta,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/promociones',
        data: {
          'nombre': nombre.trim(),
          'tipo': tipo.wireValue,
          'tipoDescuento': tipoDescuento.wireValue,
          'valorDescuento': valorDescuento,
          'vigenteDesde': _fecha(vigenteDesde),
          'vigenteHasta': _fecha(vigenteHasta),
          if (tipo == TipoPromocion.cupon) ...{
            'codigo': codigo?.trim(),
            'usosMaximos': ?usosMaximos,
          },
          if (tipo == TipoPromocion.horario) ...{
            'dias': dias.map((d) => d.wireValue).toList(),
            'horaDesde': horaDesde,
            'horaHasta': horaHasta,
          },
        },
      );
      return Promocion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Deja de aplicarse a reservas nuevas; las ya hechas no cambian.
  Future<void> desactivar(String promocionId) async {
    try {
      await _dio.delete<void>('/promociones/$promocionId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Precio con la mejor promoción para ese servicio y hora. Un [cupon] que
  /// no existe o no aplica responde 400 con el motivo ([ApiException]).
  Future<Cotizacion> cotizar({
    required String servicioId,
    required DateTime fechaHoraInicio,
    String? cupon,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/promociones/cotizacion',
        queryParameters: {
          'servicioId': servicioId,
          'fechaHoraInicio': fechaHoraInicio.toUtc().toIso8601String(),
          if (cupon != null && cupon.trim().isNotEmpty) 'cupon': cupon.trim(),
        },
      );
      return Cotizacion.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static String _fecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
