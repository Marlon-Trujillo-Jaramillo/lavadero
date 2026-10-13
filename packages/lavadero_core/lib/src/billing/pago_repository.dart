import 'package:dio/dio.dart';

import '../models/checkout_pago.dart';
import '../models/pago.dart';
import '../network/api_exception.dart';

/// Cobro de la suscripción del tenant (`/api/v1/pagos`, solo `ADMIN_TENANT`).
class PagoRepository {
  PagoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Crea un pago PENDIENTE para [subscriptionPlanId] y devuelve los datos firmados del checkout.
  /// El monto lo decide el backend a partir del plan, nunca el cliente.
  Future<CheckoutPago> iniciarPagoSuscripcion({
    required String subscriptionPlanId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/pagos/suscripcion',
        data: {'subscriptionPlanId': subscriptionPlanId},
      );
      return CheckoutPago.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Historial de pagos del tenant actual, más reciente primero.
  Future<List<Pago>> listar() async {
    try {
      final response = await _dio.get<List<dynamic>>('/pagos');
      return (response.data ?? [])
          .map((json) => Pago.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
