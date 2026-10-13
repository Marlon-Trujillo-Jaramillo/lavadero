import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  test('moneda agrupa miles y respeta decimales por moneda', () {
    expect(Formato.moneda(45000, 'COP'), r'$45.000');
    expect(Formato.moneda(1250000.4, 'COP'), r'$1.250.000');
    expect(Formato.moneda(999, 'COP'), r'$999');
    expect(Formato.moneda(12.5, 'USD'), r'$12,50');
    expect(Formato.moneda(-3000, 'COP'), r'-$3.000');
  });

  test('compacto abrevia miles y millones', () {
    expect(Formato.compacto(45000), '45 mil');
    expect(Formato.compacto(1250000), '1,3 M');
    expect(Formato.compacto(800), '800');
  });

  test('diaRelativo', () {
    final ahora = DateTime(2026, 10, 12, 9);
    expect(
      Formato.diaRelativo(DateTime(2026, 10, 12, 18), ahora: ahora),
      'Hoy',
    );
    expect(Formato.diaRelativo(DateTime(2026, 10, 13), ahora: ahora), 'Mañana');
    expect(Formato.diaRelativo(DateTime(2026, 10, 11), ahora: ahora), 'Ayer');
    expect(
      Formato.diaRelativo(DateTime(2026, 10, 15), ahora: ahora),
      'jue 15 oct',
    );
  });

  test('fechas y horas', () {
    final d = DateTime(2026, 3, 5, 7, 9);
    expect(Formato.hora(d), '07:09');
    expect(Formato.fecha(d), '05/03/2026');
    expect(Formato.fechaHora(d), '05/03/2026 07:09');
  });

  test('duracion legible', () {
    expect(Formato.duracion(const Duration(minutes: 45)), '45 min');
    expect(Formato.duracion(const Duration(minutes: 120)), '2 h');
    expect(Formato.duracion(const Duration(minutes: 374)), '6 h 14 min');
    expect(Formato.duracion(const Duration(seconds: 20)), '1 min');
  });
}
