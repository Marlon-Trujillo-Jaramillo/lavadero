import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/agenda/application/agenda_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockSchedulingRepository scheduling;
  late MockCatalogRepository catalog;
  late ProviderContainer container;

  const sucursal = Sucursal(id: 'b1', nombre: 'Centro', capacidadSimultanea: 2);
  Reserva reserva(String id, int hora) => Reserva(
    id: id,
    sucursalId: 'b1',
    servicioId: 's1',
    clienteId: 'c1',
    fechaHoraInicio: DateTime(2026, 10, 12, hora),
    fechaHoraFin: DateTime(2026, 10, 12, hora, 30),
    duracionEstimadaMinutos: 30,
    precio: 20000,
    moneda: 'COP',
    estado: ReservaEstado.pendiente,
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    scheduling = MockSchedulingRepository();
    catalog = MockCatalogRepository();
    when(() => catalog.listar()).thenAnswer((_) async => const []);
    container = ProviderContainer(
      overrides: [
        schedulingRepositoryProvider.overrideWithValue(scheduling),
        catalogRepositoryProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> iniciar() async {
    container.read(agendaControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('carga sucursales y la agenda del día ordenada por hora', () async {
    when(() => scheduling.listarSucursales()).thenAnswer((_) async => const [sucursal]);
    when(
      () => scheduling.agendaDelDia(sucursalId: 'b1', fecha: any(named: 'fecha')),
    ).thenAnswer((_) async => [reserva('r2', 11), reserva('r1', 9)]);

    await iniciar();

    final state = container.read(agendaControllerProvider);
    expect(state.sucursalSeleccionadaId, 'b1');
    expect(state.reservas.map((r) => r.id), ['r1', 'r2']);
    expect(state.contar(ReservaEstado.pendiente), 2);
  });

  test('recargar() reintenta las sucursales si su carga había fallado', () async {
    when(
      () => scheduling.listarSucursales(),
    ).thenThrow(const ApiException(message: 'Sin conexión'));
    await iniciar();
    expect(container.read(agendaControllerProvider).errorMessage, 'Sin conexión');

    when(() => scheduling.listarSucursales()).thenAnswer((_) async => const [sucursal]);
    when(
      () => scheduling.agendaDelDia(sucursalId: 'b1', fecha: any(named: 'fecha')),
    ).thenAnswer((_) async => [reserva('r1', 9)]);
    await container.read(agendaControllerProvider.notifier).recargar();

    final state = container.read(agendaControllerProvider);
    expect(state.errorMessage, isNull);
    expect(state.reservas, hasLength(1));
  });

  test('si falla la carga de otro día no quedan las reservas del día anterior', () async {
    when(() => scheduling.listarSucursales()).thenAnswer((_) async => const [sucursal]);
    when(
      () => scheduling.agendaDelDia(sucursalId: 'b1', fecha: any(named: 'fecha')),
    ).thenAnswer((_) async => [reserva('r1', 9)]);
    await iniciar();

    when(
      () => scheduling.agendaDelDia(sucursalId: 'b1', fecha: any(named: 'fecha')),
    ).thenThrow(const ApiException(message: 'Error'));
    final hoy = container.read(agendaControllerProvider).fecha;
    await container
        .read(agendaControllerProvider.notifier)
        .irADia(hoy.add(const Duration(days: 1)));

    final state = container.read(agendaControllerProvider);
    expect(state.reservas, isEmpty);
    expect(state.errorMessage, 'Error');
  });
}
