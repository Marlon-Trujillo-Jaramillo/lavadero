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

  const finanzasVacio = ResumenFinanciero(
    ingresos: 0,
    gastos: 0,
    utilidad: 0,
    moneda: 'COP',
  );

  setUp(() {
    schedulingRepository = MockSchedulingRepository();
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => resumenVacio);
    when(
      () => schedulingRepository.resumenFinanciero(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => finanzasVacio);
    when(
      () => schedulingRepository.listarGastos(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => const <Gasto>[]);

    container = ProviderContainer(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
      ],
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
        .difference(
          DateTime(state.desde.year, state.desde.month, state.desde.day),
        )
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

    await container
        .read(reportsControllerProvider.notifier)
        .cambiarRango(desde: desde, hasta: hasta);

    final state = container.read(reportsControllerProvider);
    expect(state.desde, desde);
    expect(state.hasta, hasta);
    expect(state.resumen?.totalReservasCompletadas, 5);
  });

  test('registrarGasto() guarda y recarga; sin error devuelve null', () async {
    await Future<void>.delayed(Duration.zero);
    final gasto = Gasto(
      id: 'g1',
      fecha: DateTime(2026, 11, 20),
      categoria: CategoriaGasto.arriendo,
      descripcion: 'Arriendo',
      monto: 1200000,
      moneda: 'COP',
    );
    final fecha = DateTime(2026, 11, 20);
    when(
      () => schedulingRepository.registrarGasto(
        fecha: fecha,
        categoria: CategoriaGasto.arriendo,
        descripcion: 'Arriendo',
        monto: 1200000,
      ),
    ).thenAnswer((_) async => gasto);

    final error = await container
        .read(reportsControllerProvider.notifier)
        .registrarGasto(
          fecha: fecha,
          categoria: CategoriaGasto.arriendo,
          descripcion: 'Arriendo',
          monto: 1200000,
        );

    expect(error, isNull);
    verify(
      () => schedulingRepository.registrarGasto(
        fecha: fecha,
        categoria: CategoriaGasto.arriendo,
        descripcion: 'Arriendo',
        monto: 1200000,
      ),
    ).called(1);
  });
}
