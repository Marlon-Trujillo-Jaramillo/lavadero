import 'package:admin_web/features/dashboard/application/dashboard_controller.dart';
import 'package:admin_web/features/dashboard/widgets/tendencia_ventas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

ResumenVentas _resumen({required double ingresos, required int lavados}) =>
    ResumenVentas(
      ingresosTotales: ingresos,
      moneda: 'COP',
      totalReservasCompletadas: lavados,
      serviciosMasPedidos: const [],
    );

void main() {
  testWidgets('muestra el delta de ingresos y lavados vs. ayer', (
    tester,
  ) async {
    final hoy = _resumen(ingresos: 200000, lavados: 6);
    final ayer = _resumen(ingresos: 100000, lavados: 4);
    final base = DateTime(2026, 11, 26);
    final serie = [
      for (var i = 0; i < 7; i++)
        DiaVenta(
          fecha: base.subtract(Duration(days: 6 - i)),
          resumen: i == 6
              ? hoy
              : (i == 5 ? ayer : _resumen(ingresos: 50000, lavados: 2)),
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TendenciaVentas(serie: serie, hoy: hoy, ayer: ayer),
        ),
      ),
    );

    // Ingresos 200k vs 100k -> +100 %; lavados 6 vs 4 -> +2.
    expect(find.text('+100 %'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('Cómo vas vs. ayer'), findsOneWidget);
  });

  testWidgets('sin datos de ayer no rompe', (tester) async {
    final hoy = _resumen(ingresos: 0, lavados: 0);
    final serie = [
      DiaVenta(fecha: DateTime(2026, 11, 25), resumen: hoy),
      DiaVenta(fecha: DateTime(2026, 11, 26), resumen: hoy),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TendenciaVentas(serie: serie, hoy: hoy, ayer: null),
        ),
      ),
    );

    expect(find.byType(TendenciaVentas), findsOneWidget);
  });
}
