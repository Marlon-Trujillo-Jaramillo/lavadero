import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  test('Pago.fromJson parsea el contrato de GET /pagos', () {
    final pago = Pago.fromJson({
      'id': 'p1',
      'subscriptionPlanId': 'plan1',
      'monto': 99000.00,
      'moneda': 'COP',
      'referencia': 'pago_t_abc',
      'estado': 'APROBADO',
      'creadoEn': '2026-10-12T15:00:00Z',
    });

    expect(pago.estado, PagoEstado.aprobado);
    expect(pago.monto, 99000.0);
    expect(pago.creadoEn, DateTime.utc(2026, 10, 12, 15));
  });

  test('CheckoutPago arma la URL del Web Checkout de Wompi', () {
    final checkout = CheckoutPago.fromJson({
      'pagoId': 'p1',
      'urlCheckout': 'https://checkout.wompi.co/p/',
      'llavePublica': 'pub_test_x',
      'referencia': 'pago_t_abc',
      'montoEnCentavos': 9900000,
      'moneda': 'COP',
      'firmaIntegridad': 'abc123',
      'urlRedireccion': null,
    });

    final uri = checkout.uri;
    expect(uri.queryParameters['amount-in-cents'], '9900000');
    expect(uri.queryParameters['signature:integrity'], 'abc123');
    expect(uri.queryParameters.containsKey('redirect-url'), isFalse);
  });
}
