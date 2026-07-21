import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/client/catalog/application/catalog_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late MockCatalogRepository catalogRepository;
  late ProviderContainer container;

  const servicioActivo = ServiceItem(
    id: 's1',
    nombre: 'Lavado básico',
    duracionEstimadaMinutos: 20,
    precio: 15000,
    moneda: 'COP',
    activo: true,
  );

  setUp(() {
    catalogRepository = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(catalogRepository)],
    );
    addTearDown(container.dispose);
  });

  test('carga solo servicios activos al construirse', () async {
    when(() => catalogRepository.listarActivos())
        .thenAnswer((_) async => [servicioActivo]);

    container.read(catalogControllerProvider);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(catalogControllerProvider);
    expect(state.items, [servicioActivo]);
    expect(state.isLoading, isFalse);
  });

  test('errores del repositorio quedan en errorMessage', () async {
    when(() => catalogRepository.listarActivos())
        .thenThrow(const ApiException(message: 'Sin conexión'));

    await container.read(catalogControllerProvider.notifier).cargar();

    final state = container.read(catalogControllerProvider);
    expect(state.errorMessage, 'Sin conexión');
    expect(state.isLoading, isFalse);
  });
}
