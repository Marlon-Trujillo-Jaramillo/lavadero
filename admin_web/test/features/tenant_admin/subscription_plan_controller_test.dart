import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/tenant_admin/application/subscription_plan_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockTenantRepository extends Mock implements TenantRepository {}

void main() {
  late MockTenantRepository tenantRepository;
  late ProviderContainer container;

  const plan = SubscriptionPlan(
    id: 'p1',
    nombre: 'Starter',
    precio: 99000,
    moneda: 'COP',
    maxSucursales: 1,
    maxEmpleados: 3,
    features: ['Catálogo', 'Agenda'],
  );

  setUp(() async {
    tenantRepository = MockTenantRepository();
    when(() => tenantRepository.listarPlanes()).thenAnswer((_) async => [plan]);

    container = ProviderContainer(
      overrides: [tenantRepositoryProvider.overrideWithValue(tenantRepository)],
    );
    addTearDown(container.dispose);

    container.read(subscriptionPlanControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('carga la lista de planes al construirse', () {
    final state = container.read(subscriptionPlanControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.planes, [plan]);
  });

  test('crear() llama al repositorio y recarga la lista', () async {
    when(
      () => tenantRepository.crearPlan(
        nombre: any(named: 'nombre'),
        precio: any(named: 'precio'),
        maxSucursales: any(named: 'maxSucursales'),
        maxEmpleados: any(named: 'maxEmpleados'),
        features: any(named: 'features'),
      ),
    ).thenAnswer((_) async => plan);

    await container.read(subscriptionPlanControllerProvider.notifier).crear(
          nombre: 'Starter',
          precio: 99000,
          maxSucursales: 1,
          maxEmpleados: 3,
          features: const ['Catálogo', 'Agenda'],
        );

    verify(() => tenantRepository.crearPlan(
          nombre: 'Starter',
          precio: 99000,
          maxSucursales: 1,
          maxEmpleados: 3,
          features: const ['Catálogo', 'Agenda'],
        )).called(1);
    verify(() => tenantRepository.listarPlanes()).called(greaterThan(1));
  });

  test('errores del repositorio quedan en errorMessage', () async {
    when(() => tenantRepository.listarPlanes())
        .thenThrow(const ApiException(message: 'Sin conexión'));

    await container.read(subscriptionPlanControllerProvider.notifier).cargar();

    final state = container.read(subscriptionPlanControllerProvider);
    expect(state.errorMessage, 'Sin conexión');
    expect(state.isLoading, isFalse);
  });
}
