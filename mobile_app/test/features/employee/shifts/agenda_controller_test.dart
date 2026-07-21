import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/auth/application/auth_controller.dart';
import 'package:mobile_app/features/employee/shifts/application/agenda_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

void main() {
  late MockAuthRepository authRepository;
  late MockSchedulingRepository schedulingRepository;
  late ProviderContainer container;

  final empleado = const UserProfile(
    id: 'u1',
    email: 'empleado@example.com',
    roles: [UserRole.empleado],
    tenantId: 't1',
    sucursalId: 'suc1',
  );

  setUp(() async {
    authRepository = MockAuthRepository();
    schedulingRepository = MockSchedulingRepository();
    when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
      ],
    );
    addTearDown(container.dispose);

    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  Future<void> autenticarComoEmpleado() async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthResponse(accessToken: 'a', refreshToken: 'r', expiresIn: 900, user: empleado),
    );
    await container
        .read(authControllerProvider.notifier)
        .login(tenantSlug: 'lavadero-central', email: empleado.email, password: 'secret123');
  }

  test('carga la agenda de la sucursal del empleado autenticado', () async {
    await autenticarComoEmpleado();
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
      () => schedulingRepository.agendaDelDia(
        sucursalId: any(named: 'sucursalId'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer((_) async => [reserva]);

    // Leer el provider ya dispara la carga inicial (build() -> Future.microtask(cargar));
    // no se llama `cargar()` de nuevo para no duplicar la invocación.
    container.read(agendaControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(agendaControllerProvider);
    expect(state.reservas, [reserva]);
    verify(() => schedulingRepository.agendaDelDia(sucursalId: 'suc1', fecha: any(named: 'fecha')))
        .called(1);
  });

  test('sin sucursal asignada, muestra un error en vez de llamar al repositorio', () async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthResponse(
        accessToken: 'a',
        refreshToken: 'r',
        expiresIn: 900,
        user: const UserProfile(id: 'u2', email: 'sinsucursal@example.com', roles: [UserRole.empleado]),
      ),
    );
    await container
        .read(authControllerProvider.notifier)
        .login(tenantSlug: 'lavadero-central', email: 'sinsucursal@example.com', password: 'secret123');

    await container.read(agendaControllerProvider.notifier).cargar();

    final state = container.read(agendaControllerProvider);
    expect(state.errorMessage, isNotNull);
    verifyNever(
      () => schedulingRepository.agendaDelDia(
        sucursalId: any(named: 'sucursalId'),
        fecha: any(named: 'fecha'),
      ),
    );
  });

  test('iniciar() llama al repositorio y recarga', () async {
    await autenticarComoEmpleado();
    when(
      () => schedulingRepository.agendaDelDia(
        sucursalId: any(named: 'sucursalId'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer((_) async => []);
    when(() => schedulingRepository.iniciar(any())).thenAnswer(
      (_) async => Reserva(
        id: 'r1',
        sucursalId: 'suc1',
        servicioId: 's1',
        clienteId: 'c1',
        fechaHoraInicio: DateTime.utc(2026, 8, 1, 10),
        fechaHoraFin: DateTime.utc(2026, 8, 1, 10, 20),
        duracionEstimadaMinutos: 20,
        precio: 15000,
        moneda: 'COP',
        estado: ReservaEstado.enProgreso,
      ),
    );

    await container.read(agendaControllerProvider.notifier).iniciar('r1');

    verify(() => schedulingRepository.iniciar('r1')).called(1);
    verify(
      () => schedulingRepository.agendaDelDia(sucursalId: any(named: 'sucursalId'), fecha: any(named: 'fecha')),
    ).called(greaterThan(1));
  });
}
