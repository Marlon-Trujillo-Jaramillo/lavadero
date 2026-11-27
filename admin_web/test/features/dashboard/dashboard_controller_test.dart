import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/dashboard/application/dashboard_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

void main() {
  late MockSchedulingRepository schedulingRepository;
  late ProviderContainer container;

  const resumen = ResumenVentas(
    ingresosTotales: 50000,
    moneda: 'COP',
    totalReservasCompletadas: 3,
    serviciosMasPedidos: [
      ServicioPopular(
        servicioId: 's1',
        nombreServicio: 'Lavado básico',
        cantidad: 2,
      ),
    ],
  );

  setUp(() {
    schedulingRepository = MockSchedulingRepository();
    container = ProviderContainer(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('carga el resumen de hoy al construirse', () async {
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => resumen);

    container.read(dashboardControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(dashboardControllerProvider);
    expect(state.resumen?.totalReservasCompletadas, 3);
    expect(state.isLoading, isFalse);
  });

  test('arma la serie de 7 días y el resumen de ayer', () async {
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer((_) async => resumen);

    await container.read(dashboardControllerProvider.notifier).cargar();

    final state = container.read(dashboardControllerProvider);
    expect(state.serie.length, 7);
    expect(state.resumenAyer, isNotNull);
  });

  test('errores del repositorio quedan en errorMessage', () async {
    when(
      () => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenThrow(const ApiException(message: 'Sin conexión'));

    await container.read(dashboardControllerProvider.notifier).cargar();

    final state = container.read(dashboardControllerProvider);
    expect(state.errorMessage, 'Sin conexión');
  });
}
