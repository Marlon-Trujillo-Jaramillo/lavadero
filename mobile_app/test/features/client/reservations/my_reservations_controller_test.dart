import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/client/reservations/application/my_reservations_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockSchedulingRepository schedulingRepository;
  late MockCatalogRepository catalogRepository;
  late ProviderContainer container;

  final servicio = const ServiceItem(
    id: 'srv-1',
    nombre: 'Lavado básico',
    duracionEstimadaMinutos: 20,
    precio: 15000,
    moneda: 'COP',
    activo: true,
  );

  Reserva reservaConEstado(ReservaEstado estado) => Reserva(
        id: 'r1',
        sucursalId: 'suc-1',
        servicioId: 'srv-1',
        clienteId: 'cli-1',
        fechaHoraInicio: DateTime(2026, 8, 10, 10),
        fechaHoraFin: DateTime(2026, 8, 10, 10, 20),
        duracionEstimadaMinutos: 20,
        precio: 15000,
        moneda: 'COP',
        estado: estado,
      );

  setUp(() {
    schedulingRepository = MockSchedulingRepository();
    catalogRepository = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
        catalogRepositoryProvider.overrideWithValue(catalogRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('carga las reservas y el catálogo al construirse', () async {
    when(() => schedulingRepository.misReservas())
        .thenAnswer((_) async => [reservaConEstado(ReservaEstado.pendiente)]);
    when(() => catalogRepository.listar()).thenAnswer((_) async => [servicio]);

    container.read(myReservationsControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(myReservationsControllerProvider);
    expect(state.reservas, hasLength(1));
    expect(state.servicios['srv-1'], servicio);
    expect(state.isLoading, isFalse);
  });

  test('cancelar recarga la lista tras cancelar en el repositorio', () async {
    when(() => schedulingRepository.misReservas())
        .thenAnswer((_) async => [reservaConEstado(ReservaEstado.pendiente)]);
    when(() => catalogRepository.listar()).thenAnswer((_) async => [servicio]);
    when(() => schedulingRepository.cancelar('r1'))
        .thenAnswer((_) async => reservaConEstado(ReservaEstado.cancelada));

    final controller = container.read(myReservationsControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);

    await controller.cancelar('r1');

    verify(() => schedulingRepository.cancelar('r1')).called(1);
    verify(() => schedulingRepository.misReservas()).called(2);
  });

  test('errores del repositorio quedan en errorMessage', () async {
    when(() => schedulingRepository.misReservas())
        .thenThrow(const ApiException(message: 'Sin conexión'));
    when(() => catalogRepository.listar()).thenAnswer((_) async => [servicio]);

    await container.read(myReservationsControllerProvider.notifier).cargar();

    final state = container.read(myReservationsControllerProvider);
    expect(state.errorMessage, 'Sin conexión');
    expect(state.isLoading, isFalse);
  });
}
