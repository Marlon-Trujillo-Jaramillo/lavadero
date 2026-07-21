import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/reports/application/reports_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

void main() {
  late MockSchedulingRepository schedulingRepository;
  late ProviderContainer container;

  const resumenVacio = ResumenVentas(
    ingresosTotales: 0,
    moneda: 'COP',
    totalReservasCompletadas: 0,
    serviciosMasPedidos: [],
  );

  setUp(() {
    schedulingRepository = MockSchedulingRepository();
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => resumenVacio);

    container = ProviderContainer(
      overrides: [schedulingRepositoryProvider.overrideWithValue(schedulingRepository)],
    );
    addTearDown(container.dispose);

    container.read(reportsControllerProvider);
  });

  test('el rango por defecto son los últimos 7 días', () async {
    await Future<void>.delayed(Duration.zero);

    final state = container.read(reportsControllerProvider);
    // Comparación por fecha calendario, no por duración exacta: `desde` y
    // `hasta` vienen de dos llamadas a `DateTime.now()` separadas por
    // microsegundos, así que `.difference(...).inDays` puede truncar a 5.
    final dias = DateTime(state.hasta.year, state.hasta.month, state.hasta.day)
        .difference(DateTime(state.desde.year, state.desde.month, state.desde.day))
        .inDays;
    expect(dias, 6);
  });

  test('cambiarRango() recarga el resumen con el nuevo rango', () async {
    await Future<void>.delayed(Duration.zero);
    final desde = DateTime(2026, 1, 1);
    final hasta = DateTime(2026, 1, 31);

    const resumenEnero = ResumenVentas(
      ingresosTotales: 100000,
      moneda: 'COP',
      totalReservasCompletadas: 5,
      serviciosMasPedidos: [],
    );
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => resumenEnero);

    await container.read(reportsControllerProvider.notifier).cambiarRango(desde: desde, hasta: hasta);

    final state = container.read(reportsControllerProvider);
    expect(state.desde, desde);
    expect(state.hasta, hasta);
    expect(state.resumen?.totalReservasCompletadas, 5);
  });
}
