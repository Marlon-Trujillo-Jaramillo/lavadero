import 'package:admin_web/features/crm/application/mensaje_sugerido.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

ClienteCrm _cliente(SegmentoCliente segmento, {int visitas = 1}) => ClienteCrm(
  id: 'c1',
  nombre: '  Ana María Gómez',
  email: 'ana@example.com',
  visitas: visitas,
  gastoTotal: 0,
  moneda: 'COP',
  ultimaVisita: DateTime.now().subtract(const Duration(days: 50)),
  vehiculosActivos: 0,
  segmento: segmento,
);

void main() {
  test('cada segmento tiene su propio mensaje, saludando por el nombre', () {
    final asuntos = {
      for (final s in SegmentoCliente.values)
        mensajeSugerido(_cliente(s)).asunto,
    };
    expect(asuntos, hasLength(SegmentoCliente.values.length));
    expect(
      mensajeSugerido(_cliente(SegmentoCliente.enRiesgo)).cuerpo,
      startsWith('Hola Ana, hace 50 días'),
    );
    expect(
      mensajeSugerido(_cliente(SegmentoCliente.frecuente, visitas: 8)).cuerpo,
      contains('8 visitas'),
    );
  });

  test('el mailto codifica espacios como %20 y no como +', () {
    final uri = correoSugerido(_cliente(SegmentoCliente.nuevo));

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'ana@example.com');
    expect(uri.toString(), contains('subject=%C2%A1Gracias%20por'));
    expect(uri.toString(), isNot(contains('+')));
  });
}
