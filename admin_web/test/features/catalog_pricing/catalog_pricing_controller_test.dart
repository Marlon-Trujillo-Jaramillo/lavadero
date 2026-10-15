import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/catalog_pricing/application/catalog_pricing_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockCatalogRepository catalogRepository;
  late ProviderContainer container;

  const servicio = ServiceItem(
    id: 's1',
    nombre: 'Lavado básico',
    duracionEstimadaMinutos: 20,
    precio: 15000,
    moneda: 'COP',
    activo: true,
  );

  setUp(() async {
    catalogRepository = MockCatalogRepository();
    when(() => catalogRepository.listar()).thenAnswer((_) async => [servicio]);

    container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(catalogRepository)],
    );
    addTearDown(container.dispose);

    container.read(catalogPricingControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('carga la lista de servicios al construirse', () {
    final state = container.read(catalogPricingControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.items, [servicio]);
  });

  test('crear() llama al repositorio y recarga la lista', () async {
    when(
      () => catalogRepository.crear(
        nombre: any(named: 'nombre'),
        descripcion: any(named: 'descripcion'),
        duracionEstimadaMinutos: any(named: 'duracionEstimadaMinutos'),
        precio: any(named: 'precio'),
      ),
    ).thenAnswer((_) async => servicio);

    await container.read(catalogPricingControllerProvider.notifier).crear(
          nombre: 'Lavado básico',
          duracionEstimadaMinutos: 20,
          precio: 15000,
        );

    verify(() => catalogRepository.crear(
          nombre: 'Lavado básico',
          descripcion: null,
          duracionEstimadaMinutos: 20,
          precio: 15000,
        )).called(1);
    verify(() => catalogRepository.listar()).called(greaterThan(1));
  });

  test('cambiarEstado() desactiva un servicio y recarga', () async {
    when(() => catalogRepository.cambiarEstado(id: any(named: 'id'), activo: any(named: 'activo')))
        .thenAnswer((_) async => servicio);

    await container
        .read(catalogPricingControllerProvider.notifier)
        .cambiarEstado(id: 's1', activo: false);

    verify(() => catalogRepository.cambiarEstado(id: 's1', activo: false)).called(1);
  });

  test('errores del repositorio quedan en errorMessage', () async {
    when(() => catalogRepository.listar())
        .thenThrow(const ApiException(message: 'Sin conexión'));

    await container.read(catalogPricingControllerProvider.notifier).cargar();

    final state = container.read(catalogPricingControllerProvider);
    expect(state.errorMessage, 'Sin conexión');
    expect(state.isLoading, isFalse);
  });

  test('cambiarEstado() deja el error en el estado en vez de lanzarlo', () async {
    when(() => catalogRepository.cambiarEstado(id: any(named: 'id'), activo: any(named: 'activo')))
        .thenThrow(const ApiException(message: 'No permitido'));

    await container
        .read(catalogPricingControllerProvider.notifier)
        .cambiarEstado(id: 's1', activo: false);

    final state = container.read(catalogPricingControllerProvider);
    expect(state.errorMessage, 'No permitido');
    expect(state.cambiandoEstadoId, isNull);
  });
}
