import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/client/booking/application/booking_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

void main() {
  late MockCatalogRepository catalogRepository;
  late MockSchedulingRepository schedulingRepository;
  late ProviderContainer container;

  const servicio = ServiceItem(
    id: 's1',
    nombre: 'Lavado básico',
    duracionEstimadaMinutos: 20,
    precio: 15000,
    moneda: 'COP',
    activo: true,
  );
  const sucursal = Sucursal(id: 'suc1', nombre: 'Principal', capacidadSimultanea: 1);

  setUp(() async {
    catalogRepository = MockCatalogRepository();
    schedulingRepository = MockSchedulingRepository();
    when(() => catalogRepository.listarActivos()).thenAnswer((_) async => [servicio]);
    when(() => schedulingRepository.listarSucursales()).thenAnswer((_) async => [sucursal]);

    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalogRepository),
        schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
      ],
    );
    addTearDown(container.dispose);

    // Deja que la carga inicial de servicios/sucursales (disparada por
    // `build()`) termine antes de que cada test actúe — si no, corre en
    // paralelo con `reservar()` y su `clearError` pisa el estado de error.
    container.read(bookingControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('carga servicios activos y sucursales al construirse', () async {
    final state = container.read(bookingControllerProvider);
    expect(state.servicios, [servicio]);
    expect(state.sucursales, [sucursal]);
    expect(state.isLoading, isFalse);
  });

  test('reservar() guarda la reserva creada en el estado', () async {
    final inicio = DateTime.utc(2026, 8, 1, 10);
    final reserva = Reserva(
      id: 'r1',
      sucursalId: 'suc1',
      servicioId: 's1',
      clienteId: 'c1',
      fechaHoraInicio: inicio,
      fechaHoraFin: inicio.add(const Duration(minutes: 20)),
      duracionEstimadaMinutos: 20,
      precio: 15000,
      moneda: 'COP',
      estado: ReservaEstado.pendiente,
    );
    when(
      () => schedulingRepository.crear(
        sucursalId: any(named: 'sucursalId'),
        servicioId: any(named: 'servicioId'),
        fechaHoraInicio: any(named: 'fechaHoraInicio'),
      ),
    ).thenAnswer((_) async => reserva);

    await container.read(bookingControllerProvider.notifier).reservar(
          sucursalId: 'suc1',
          servicioId: 's1',
          fechaHoraInicio: inicio,
        );

    final state = container.read(bookingControllerProvider);
    expect(state.reservaCreada, reserva);
    expect(state.isSubmitting, isFalse);
  });

  test('reservar() surfaces ApiException.message on failure', () async {
    when(
      () => schedulingRepository.crear(
        sucursalId: any(named: 'sucursalId'),
        servicioId: any(named: 'servicioId'),
        fechaHoraInicio: any(named: 'fechaHoraInicio'),
      ),
    ).thenThrow(const ApiException(message: 'No hay cupo disponible'));

    await container.read(bookingControllerProvider.notifier).reservar(
          sucursalId: 'suc1',
          servicioId: 's1',
          fechaHoraInicio: DateTime.utc(2026, 8, 1, 10),
        );

    final state = container.read(bookingControllerProvider);
    expect(state.errorMessage, 'No hay cupo disponible');
    expect(state.reservaCreada, isNull);
  });
}
